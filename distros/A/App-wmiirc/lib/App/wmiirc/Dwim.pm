# ABSTRACT: A default action that does something useful (hopefully)
package App::wmiirc::Dwim;
{
  $App::wmiirc::Dwim::VERSION = '1.000';
}
use User::pwent;
use URI::Escape qw(uri_escape_utf8);
use App::wmiirc::Plugin;
with 'App::wmiirc::Role::Action';

my %aliases = config("alias", {});

for my $alias(keys %aliases) {
  my $target = $aliases{$alias};

  _getglob("action_$alias") = sub {
    my($self, @args) = @_;
    $self->action_default(sprintf $target, uri_escape_utf8 "@args");
  };
}

sub action_xsel(Modkey-o) {
  my($self, @args) = @_;
  open my $fh, "-|", "xsel", "-o";
  my $selection = join "", <$fh>;
  $self->action_default($selection, @args);
}

sub action_default {
  my($self, $action, @args) = @_;

  if($action =~ m{^[/~]}) {
    # A file?
    my $file = $action =~ s{^~([^/]*)}{$1 ?
      (getpwnam($1) || die "No such user: $1\n")->dir : $ENV{HOME}}re;

    if(-d $file) {
      # TODO: Use xdg-open stuff?
      system config("commands", "file_manager") . " '$file'&";
    } else {
      system config("commands", "editor") . " '$file'&";
    }
  } elsif($action =~ m{^\w+://}) {
    system config("commands", "browser") . " '$action'&";
  } elsif($action =~ m{^[\w.+-]+@}) {
    $action =~ s/\@$//; # so I can type foo@ but it gets parsed properly
    system config("commands", "mail") . " '$action'&";
  } else {
    my($host, $rest) = split m{/}, $action, 2;

    if(exists $aliases{$host}) {
      system config("commands", "browser") . " '" .
          sprintf($aliases{$host}, uri_escape_utf8 "$rest@args") . "'&";
    # TODO: Use IO::Async's lookup code for non-blocking here
    } elsif($host =~ /^\S+:\d+/ || $host !~ / / && gethostbyname $host) {
      system config("commands", "browser") . " 'http://$action'&";
    } else {
      system config("commands", "browser") . " 'https://www.google.com/search?q="
        . uri_escape_utf8(join " ", $action, @args) . "'&";
    }
  }
}

sub _getglob :lvalue {
  no strict 'refs';
  *{shift()};
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Dwim - A default action that does something useful (hopefully)

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

