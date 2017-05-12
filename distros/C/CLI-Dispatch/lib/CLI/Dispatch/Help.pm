package CLI::Dispatch::Help;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );
use Class::Unload;
use Class::Inspector;
use Encode;
use Pod::Simple::Text;
use Path::Tiny;
use String::CamelCase;
use Term::Encoding ();
use Try::Tiny;

my $term_encoding = eval {
  find_encoding(Term::Encoding::get_encoding())
} || 'utf8';


sub options {qw( from|decode=s to|encode=s )}

sub extra_namespaces {}

sub run {
  my ($self, @args) = @_;

  my $text;
  if ( @args ) {
    $text = $self->extract_pod( @args );
  }
  else {
    $text = $self->list_commands;
  }

  $self->output( $text );
}

sub output {
  my ($self, $text, $no_print) = @_;

  unless ( Encode::is_utf8( $text ) ) {
    $text = decode( $self->option('from') || 'utf8', $text )
  }
  $text = encode( $self->option('to') || $term_encoding, $text );

  print $text unless $no_print;

  return $text;
}

sub extract_pod {
  my ($self, $command) = @_;

  my $content = $self->_lookup( $command );

  unless ( $content ) {
    $self->logger(1) unless $self->logger;
    $self->log( warn => "$command is not found" );
    return $self->list_commands;
  }

  my $pod = $self->_parse_pod($content);

  return $self->extract_pod_body($pod);
}

sub extract_pod_body {
  my ($self, $pod) = @_;

  # remove the first ("NAME") section as the command does not
  # always belong to the same namespace as the dispatcher/script.
  # (default CLI::Dispatch namespace may be confusing for end users)
  $pod =~ s/^\S+\s+(.+?)\n(?=\S)//s;

  return $pod;
}

sub list_commands {
  my $self = shift;

  my @paths = map { s{::}{/}g; $_ } $self->_namespaces;

  my %found;
  my %classes;
  my $maxlength = 0;
  foreach my $inc ( @INC ) {
    foreach my $path ( @paths ) {
      my $dir = path( $inc, $path );
      next unless $dir->exists && $dir->is_dir;
      my $iter = $dir->iterator({recurse => 1});
      while (my $file = $iter->()) {
        next if $file->is_dir;

        my $basename = $file->basename;
           $basename =~ s/\.(?:pm|pod)$//;

        next if defined $found{$basename};

        (my $class = $path) =~ s{/}{::}g;
        $class .= '::'.$basename;
        $classes{$class} = 1;

        # ignore base class
        next if $class eq 'CLI::Dispatch::Command';

        my $podfile = $file->parent->child($basename . '.pod');
        my $pmfile  = $file->parent->child($basename . '.pm');

        # should always parse .pod file if it exists
        my $pod = $self->_parse_pod($podfile->exists ? $podfile->slurp : $file->slurp);

        $basename = $self->convert_command($basename);

        $found{$basename} ||= $self->extract_brief_description($pod, $class);

        # check availability
        if ( $pmfile->exists ) {
          my $loaded = Class::Inspector->loaded($class);
          Class::Unload->unload($class) if $loaded;
          my $error;
          try   { eval "require $class" or die }
          catch { $error = $_ || 'Obscure error' };
          if ($error) {
            if ($error =~ /^Can't locate /) {
              # most probably this is a subcommand of some command
              # (ie. in a wrong namespace)
              delete $found{$basename};
            }
            else {
              $found{$basename} .= " [disabled: compile error]";
            }
          }
          elsif ( $class->can('check') ) {
            try   { $class->check }
            catch {
              $error = $_ || 'Obscure error';
              $error =~ s/\s+at .+? line \d+\.?\s*$//;
              $found{$basename} .= " [disabled: $error]";
            };
          }
          Class::Unload->unload($class) unless $loaded;
        }

        my $len = length $basename;
        $maxlength = $len if $maxlength < $len;
      }
    }
  }

  my $text = '';
  my $format = "%-${maxlength}s - %s\n";
  foreach my $key ( sort keys %found ) {
    $text .= sprintf($format, $key, $found{$key});
  }
  return $text;
}

sub convert_command {
  my ($self, $command) = @_;
  String::CamelCase::decamelize( $command );
}

sub extract_brief_description {
  my ($self, $pod, $class) = @_;

  # "NAME" header may be localized
  my ($brief_desc) = $pod =~ /^\S+\s+$class\s+\-\s+(.+?)\n/s;

  return $brief_desc || '';
}

sub _parse_pod {
  my ($self, $file) = @_;

  my $parser = Pod::Simple::Text->new;
     $parser->output_string( \my $pod );
     $parser->parse_string_document("$file");

  return $pod;
}

sub _namespaces {
  my $self = shift;

  my %seen;
  return grep { !$seen{$_}++ } (
    $self->extra_namespaces,
    @{ $self->option('_namespaces') || [] },
    'CLI::Dispatch'
  );
}

sub _lookup {
  my ($self, $command) = @_;

  my @paths;
  if ($command =~ s/^\+//) {
    $command =~ s{::}{/}g;
    @paths = $command;
  }
  else {
    @paths = map { s{::}{/}g; "$_/$command" } $self->_namespaces;
  }

  foreach my $inc ( @INC ) {
    foreach my $path ( @paths ) {
      foreach my $ext (qw( pod pm )) {
        my $file = path( $inc, "$path.$ext" );
        return $file->slurp if $file->exists;
      }
    }
  }

  # probably it's embedded in the caller...
  my $ct = 0;
  my %seen;
  while (my @caller = caller($ct++)) {
    next if $caller[0] =~ /^CLI::Dispatch(::.+)?$/;
    next if $seen{$caller[0]}++;
    my $content = path($caller[1])->slurp;
    for my $path ( @paths ) {
      (my $package = $path) =~ s{/}{::}g;
      if ($content =~ /=head1\s+\S+\s+$package/s) { # hopefully NAME
        return $content;
      }
    }
  }

  return;
}

1;

__END__

=head1 NAME

CLI::Dispatch::Help - show help

=head1 SYNOPSIS

  to list available commands:

    > perl your_script.pl

  to show help of a specific command:

    > perl your_script.pl help command

  you may want to encode/decode the text:

    > perl your_script.pl command --help --from=utf-8 --to=shift_jis

=head1 DESCRIPTION

This command is used to show help, and expects the first section of the pod of
each command to be a NAME (or equivalent) section with a class name and brief
description of the class/command, separated by a hyphen and arbitrary numbers
of white spaces (like this pod).

If you distribute your script, you may want to make a subclass of this command
just to provide more user-friendly document (content-wise and language-wise).

=head1 METHODS

=head2 run

shows a list of available commands (with brief description if any), or help
(pod) of a specific command.

=head2 options

by default, encode/decode options are available to change encoding.

=head2 extra_namespaces

by default, this command looks for commands just under the namespace you
specified in the script/dispatcher. However, you may want it to look into other
directories to show something like tutorials. For example, if you make a
subclass like this:

  package MyScript::Help;
  use strict;
  use base qw( CLI::Dispatcher::Help );

  sub extra_namespaces { qw( MyScript::Cookbook ) }
  1;

then, when you run the script like this, MyScript/Cookbook/Install.pod (or .pm)
will be shown:

  > perl myscript.pl help install

You may even make it language-conscious:

  package MyScript::Help;
  use strict;
  use base qw( CLI::Dispatcher::Help );

  sub options {qw( lang=s )}

  sub extra_namespaces {
    my $self = shift;
    my $lang = uc( $self->option('lang') || 'EN' );
    return (
      'MyScript::Cookbook::'.$lang,
      'MyScript::Cookbook::EN',     # in case of $lang is wrong
    );
  1;

This can be used to provide more user-friendly documents (without overriding
commands themselves).

=head2 output

by default, takes a text, decode/encode it if necessary, prints the result to
stdout, and returns the text.

=head2 extract_pod

takes a command and looks for the actual pm/pod file to read its pod, and
returns the pod (without the first section to hide the class name and brief
description).

=head2 extract_pod_body

takes a pod, removes the first ("NAME") section, and returns the pod. You may
also want to hide other sections like "AUTHOR" and "COPYRIGHT" for end users.

=head2 list_commands

returns a concatenated text of a list of the available commands with brief
description (if any).

=head2 convert_command

takes a name of a command, converts it if necessary (decamelize by default),
and returns the result.

=head2 extract_brief_description

takes a pod, extract the first ("NAME") section (actually the first line of the
first section), and returns it. Override this if you don't want to cut longer
(multi-lined) description.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
