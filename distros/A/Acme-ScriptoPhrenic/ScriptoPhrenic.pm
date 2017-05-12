package Acme::ScriptoPhrenic;
use strict;use warnings;use Carp;
use version;our $VERSION = qv('0.0.2');
open 0 or croak "Can't pregrob '$0': $!";
my @grob;my $past = 0;
for(<0>){chomp;s/\s*\#.*//;s/^\s+|\s+$//g;last if /^\_\_END\_\_/;if(!$past){if(/Acme::ScriptoPhrenic/){$past=1;}next;}push @grob, $_ if $_ && $_ =~ m/\S/;}
local $SIG{__WARN__} = sub { 1 };
croak 'No peronsalities!' if @grob == 0;
do $grob[ rand @grob ];exit; 
1;
__END__

=head1 NAME

Acme::ScriptoPhrenic - Perl extension to create scripts that randomly change personality

=head1 SYNOPSIS

   use Acme::ScriptoPhrenic;
   path/to/script.pl
   path/to/another_script.pl  
   path/to/you/guessed/it/another/script.pl

=head1 DESCRIPTION

Each line after the use() statement (unless empty or a comment) is considered a "personality".

When run,  your script becomes one of the personalities at random, so you'll never know what you're going to get.

Comments and whitespace are ok.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
