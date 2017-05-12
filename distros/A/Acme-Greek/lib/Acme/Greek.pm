package Acme::Greek;
use strict;
use utf8;

my $latin  = q{ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz};
my $greek  = q{ΑΒΨΔΕΦΓΗΙΞΚΛΜΝΟΠQΡΣΤΘΩWΧΥΖαβψδεφγηιξκλμνοπqρστθωςχυζ};

sub encode {$_ = shift; eval "tr/$latin/$greek/"; $_}
sub decode {$_ = shift; eval "tr/$greek/$latin/"; $_}
open 0 or print "can't encode '$0'\n" and exit;
binmode 0, ':utf8';
(my $code = join '', <0>) =~ s/^\s*use\s+Acme::Greek\s*;\s*//ms;
do {eval decode $code; exit;} if $code =~ /[$greek]/;
open 0, ">$0" or print "ψαν'τ ενψοδε '$0'"; 
binmode 0, ':utf8';
print {0} "use Acme::Greek;\n", encode $code and exit;

=head1 NAME

Acme::Greek - Ιτ'σ αλλ γρεεκ το με!

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Tired of co-workers complaining that your code is "all greek to them"?
Need to send your perl to the local mathematician for review?  Look no
further than Acme::Greek, which will greek-ify your code but still
be executable.  

Example:

     use Acme::Greek;
     print "Hello, world.\n";

When you run this program, it will greek-ify itself:

     use Acme::Greek;
     πριντ "Ηελλο, ςορλδ.\ν";

This might not look like valid perl, but it is.  Run the program
again, and it prints:

    Hello, world.

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-greek at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Greek>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
