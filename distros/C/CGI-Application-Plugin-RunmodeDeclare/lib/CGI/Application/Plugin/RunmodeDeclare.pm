package CGI::Application::Plugin::RunmodeDeclare;
{
  $CGI::Application::Plugin::RunmodeDeclare::VERSION = '0.10';
}

use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::RunmodeDeclare - Declare runmodes with keywords

=head1 VERSION

version 0.10

=cut

use base 'Devel::Declare::MethodInstaller::Simple';
use Carp qw(croak);

sub import {
    my $class = shift;
    my $caller = caller;

    my %remap = (
            runmode   => runmode   =>
            startmode => startmode =>
            errormode => errormode =>
            invocant  => '$self' =>
            into      => $caller,
            @_ );

    $class->install_methodhandler(
        into         => $remap{into},
        name         => $remap{runmode},
        pre_install  => \&_setup_runmode,
        invocant     => $remap{invocant},
    );
    $class->install_methodhandler(
        into         => $remap{into},
        name         => $remap{startmode},
        pre_install  => \&_setup_startmode,
        invocant     => $remap{invocant},
    );
    $class->install_methodhandler(
        into         => $remap{into},
        name         => $remap{errormode},
        pre_install  => \&_setup_errormode,
        invocant     => $remap{invocant},
    );
}


my %REGISTRY;
# per-macro setup
sub _split {
    my $n = shift; my ($p,$l) = $n =~ /^(.*?)(?:::(\w*))?$/; return ($p, $l);
}
sub _setup_runmode {
    my ($fullname, $code) = @_;
    my ($pkg, $name) = _split($fullname);
    $pkg->add_callback( init => sub { $_[0]->run_modes([ $name ]) } );
}
sub _setup_startmode {
    my ($fullname, $code) = @_;
    no strict 'refs'; no warnings 'uninitialized';
    my ($pkg, $name) = _split($fullname);
    # compile time check
    croak "start mode redefined (from $REGISTRY{$pkg}{start_mode_installed})" if $REGISTRY{$pkg}{start_mode_installed};
    $pkg->add_callback(
        init => sub {
            # run time check
            return if exists $_[0]->{__START_MODE_SET_BY_RUNMODEDECLARE};
            $_[0]->run_modes( [$name] );
            $_[0]->start_mode($name);
            $_[0]->{__START_MODE_SET_BY_RUNMODEDECLARE} = 1;
        }
    );
    $REGISTRY{$pkg}{start_mode_installed} = $fullname;
}
sub _setup_errormode {
    my ($fullname, $code) = @_;
    no strict 'refs'; no warnings 'uninitialized';
    my ($pkg, $name) = _split($fullname);
    croak "error mode redefined (from $REGISTRY{$pkg}{error_mode_installed})" if $REGISTRY{$pkg}{error_mode_installed};
    $pkg->add_callback(
        init => sub {
            return if exists $_[0]->{__ERROR_MODE_SET_BY_RUNMODEDECLARE};
            $_[0]->error_mode($name);
            $_[0]->{__ERROR_MODE_SET_BY_RUNMODEDECLARE} = 1;
        }
    );
    $REGISTRY{$pkg}{error_mode_installed} = $fullname;
}

=begin pod-coverage

=over 4

=item strip_name - we hook into this to install cgiapp callbacks

=item parse_proto - proto parser

=item inject_parsed_proto - turn it into code

=back

=end pod-coverage

=cut

sub strip_name {
    my $ctx = shift;

    my $name = $ctx->SUPER::strip_name;
    $ctx->{pre_install}->($ctx->get_curstash_name . '::' . $name);

    return $name;
}

sub parse_proto {
    my $self = shift;
    my ($proto) = @_;
    $proto ||= '';
    $proto =~ s/[\r\n]/ /sg;
    $proto =~ s/^\s+//; $proto =~ s/\s+$//;

    my $invocant = $self->{invocant};
    $invocant = $1 if $proto =~ s{^(\$\w+):\s*}{};

    my @args =
        map { m{^ ([\$@%])(\w+) }x ? [$1, $2] : () }
        split /\s*,\s*/,
        $proto
    ;

    return (
        $invocant,
        $proto,
        @args,
    );
}

# Turn the parsed signature into Perl code
sub inject_parsed_proto {
    my $self      = shift;
    my ($invocant, $proto, @args) = @_;

    my @code;
    push @code, "my $invocant = shift;";
    push @code, "my ($proto) = \@_;" if defined $proto and length $proto;

    for my $sig (@args) {
        my ($sigil, $name) = @$sig;
        push @code, _default_for($sigil,$name,$invocant) if $sigil eq '$'; # CA->param only handles scalars
        push @code, _default_for($sigil,$name,"${invocant}->query");
        push @code, _php_style_default_for($sigil,"${name}","${invocant}->query") if $sigil eq '@'; # support PHP-style foo[] params
    }

    return join ' ', @code;
}

sub _default_for {
    my $sigil = shift;
    my $name = shift;
    my $invocant = shift;

    return
          "${sigil}${name} = ${invocant}->param('${name}') unless "
        . ( $sigil eq '$' ? 'defined' : '' )
        . " ${sigil}${name}; ";

}

sub _php_style_default_for {
    my $sigil = shift;
    my $name = shift;
    my $invocant = shift;

    my $varname = $name . '[]';
    return
          "${sigil}${name} = ${invocant}->param('${name}[]') unless "
        . " ${sigil}${name}; ";

}


1; # End of CGI::Application::Plugin::RunmodeDeclare

__END__

=head1 SYNOPSIS

    package My::CgiApp;

    use base 'CGI::Application';
    use CGI::Application::Plugin::RunmodeDeclare;

    startmode hello { "Hello!" }

    runmode world($name) {
        return $self->hello
        . ', '
        . $name || "World!";
    }

    errormode oops($c: $exception) {
        return "Something went wrong at "
        . $c->get_current_runmode
        . ". Exception: $exception";
    }

=head1 DESCRIPTION

This module allows you to declare run modes with a simple keyword. It provides
the same features as L<Method::Signatures::Simple>.

It respects inheritance: run modes defined in the superclass are also available
in the subclass.

Beyond automatically registering the run mode, and providing C<$self>, it also
optionally pulls named parameters from C<< $self->query->param >> or
C<< $self->param >>.

=over 4

=item * Basic example

    runmode foo { $self->bar }

This declares the run mode "foo". Notice how C<$self> is ready for use.

=item * Rename invocant

    runmode bar ($c:) { $c->baz }

Same as above, only use C<$c> instead of C<$self>.

    use CGI::Application::Plugin::RunmodeDeclare invocant => '$c';
    runmode baz { $c->quux }

Same as above, but every runmode gets C<$c> by default. You can still say C<runmode ($self:)>
to rename the invocant.

=item * With a parameter list

    runmode baz ( $id, $name ) {
        return $self->wibble("I received $id and $name from a form submission
                              or a method invocation.");
    }

Here, we specify that the method expects two parameters, C<$id> and C<$name>.
Values can be supplied through a method call (e.g. C<< $self->baz(1, "me") >>),
or from the cgiapp object (e.g. C<< $self->param( id => 42 ) >>), or from the
query object (e.g. from C</script?id=42;name=me>).

=item * Code attributes

    runmode secret :Auth { ... }

Code attributes are supported as well.

=item * Combining with other ways to set run modes

This all works:

    sub setup {
        my $self = shift;
        $self->run_modes([ qw/ foo / ]);
    }

    sub foo {
        my $self = shift;
        return $self->other;
    }

    runmode bar {
        return $self->other;
    }

    sub other : Runmode {
        my $self = shift;
        return $self->param('other');
    }

So you can still use the classic way of setting up run modes, and you can
still use L<CGI::Application::Plugin::AutoRunmode>, *and* you can mix and match.

=back

=head1 EXPORT

=over 4

=item * errormode

Define the run mode that serves as C<< $self->error_mode >>. You can only declare one
C<errormode> per package.

=item * startmode

Define the run mode that serves as C<< $self->start_mode >>. You can only declare one
C<startmode> per package.

=item * runmode

Define run mode.

=back

=head1 AUTHOR

Rhesa Rozendaal, C<< <rhesa at cpan.org> >>

=head1 DIAGNOSTICS

=over 4

=item * error mode redefined (from %s) at %s line %s

You tried to install another errormode. Placeholders are filled with

 * fully qualified name of existing errormode
 * file name
 * line number

=item * start mode redefined (from %s) at %s line %s

You tried to install another startmode. Placeholders are filled with

 * fully qualified name of existing startmode
 * file name
 * line number

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-runmodedeclare at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-RunmodeDeclare>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::RunmodeDeclare


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-RunmodeDeclare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-RunmodeDeclare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-RunmodeDeclare>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-RunmodeDeclare>

=back


=head1 ACKNOWLEDGEMENTS

Matt S. Trout for L<Devel::Declare>, and Michael G. Schwern for providing
the inspiration with L<Method::Signatures>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
