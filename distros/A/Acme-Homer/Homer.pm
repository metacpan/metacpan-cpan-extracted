package Acme::Homer;

use strict;
use warnings;
use Carp;

use version;our $VERSION = qv('0.0.2');

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(no_beer_no_tv_make_homer_go_crazy 
                 doh  why_you_little  mmm  woohoo );

sub doh { goto &Carp::croak; }

sub mmm { goto &Carp::carp; }

sub woohoo { ref $_[0] eq 'GLOB' ? print {shift} @_ : print @_; }

sub why_you_little { goto &Carp::cluck; }

sub no_beer_no_tv_make_homer_go_crazy { goto &Carp::confess; }

1;

__END__

=head1 NAME

Acme::Homer - Perl extension to put a little Homer in your code

=head1 SYNOPSIS

  use Acme::Homer;

  woohoo "Free beer alright!\n";  
  mmm "Mcribwhich\n" if $sandwhich eq 'Processed Pork';
  open my $beer, $marge or doh "could not open $beer: $!";
  ...

=head1 DESCRIPTION

Use homerism's instead of the normal boring stuff :)

=head1 Putting the "fun" in FUNCTIONS

=head2 woohoo()

Use this instead of print

The only difference is that to print to a filehandle you must do it like so:

    open my $list_fh, '<', 'list.txt' or die "Could not open list.txt: $!";
    woohoo $list_fh, "whatever";
    woohoo \*STDERR, "whatever";

If anyone knows of a way to make:

    woohoo STDERR "whatever";

work exactly like

    print STDERR "whatever";

Just let me know and I'll put your name down here as the "In your face Flanders" of the day!!

=head2 mmm()

Use this instead of Carp::carp()

=head2 why_you_little()

Use this instead of Carp::cluck()

=head2 doh()

Use this instead of Carp::croak()

=head2 no_beer_no_tv_make_homer_go_crazy()

Use this instead of Carp::confess()

=head2 EXPORT

All of the funtions described above are exported. 
Usually I don't do that but I figured: "hey, whats the point of getting uptight about your name space being polluted when you're using a Homer module"

=head1 TODO

If you think of any good Homerisms that would make good replacements for real funtion names lemme know!

=head1 In your face Flanders 

This is really a "thanks for contributing" section but I figured why not give it a Homer type name:

=over 4

=item Thanks to Jose Alves de Castro for catching a POD typo.

=back

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
