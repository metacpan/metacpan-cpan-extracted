package Catalyst::TraitFor::Log::Audio;

=head1 NAME

Catalyst::TraitFor::Log::Audio - Audible debug messages for Catalyst.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

use 5.008001;

=head1 SYNOPSIS

In MyApp.pm, after calling __PACKAGE__setup():

    Moose::Util::apply_all_roles(MyApp->log, 'Catalyst::TraitFor::Log::Audio');

In your shell environment:

    SPEAK=1, or export SPEAK=1

In your controllers thereafter:

    $c->log->speak("The value of foo is $foo");

=head1 DESCRIPTION

Very simple role for Catalyst::Log that enables debug output to go to OS X's
'say' command via $c->log->speak();

At the moment, as computers are fast - multiple speaks will pile up.  I will fix
this soon, so they queue.  May also work with tonal debugging in the future. Now
uses say on darwin/OS X, and espeak on Linux.

This module shows the potential and handiness of roles for Catalyst.

Requires Catalyst (CataMoose) 5.8+

=cut

use Moose::Role;

=head2 speak

Given text as an argument, send it to OS X's say(1), or Linux's espeak
command.

=cut

sub speak
{
    my ($self, $txt) = @_;
    
    return unless $txt;
    
    if($ENV{'SPEAK'})
    {
        if($^O eq 'darwin')
        {
            system("say $txt &");
        }
        elsif($^O eq 'linux')
        {
            system("espeak $txt &");
        }
    }
}

=head1 SEE ALSO

L<Catalyst::Log>, L<Moose::Role>

=cut

=head1 BUGS

=head1 SUPPORT

=head1 CONTRIBUTORS

=head1 AUTHOR

Russell Jurney, C << <rjurney at cloudstenography.com> >>

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose::Role;

1;