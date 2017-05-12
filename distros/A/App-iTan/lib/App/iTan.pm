# ================================================================
package App::iTan;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App qw(Color);

app_namespace 'App::iTan::Command';

our $VERSION = '1.06';
our $AUTHORITY = 'cpan:MAROS';

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME 

App::iTan - Secure management of iTANs for online banking

=head1 SYNOPSIS

 # Import a list of itans
 console$ itan import --file itanlist.txt
 
 # Fetch an itan and mark it as used (after password prompt)
 console$ itan get --index 15 --memo "paid rent 06/2012"
 
 # List all itans
 console$ itan list

=head1 DESCRIPTION

This command line application facilitates the secure handling of iTANs 
(indexed Transaction Numbers) as used by various online banking tools. 

iTANs are encrypted using L<Crypt::Twofish> and are by default stored 
in a SQLite database located at ~/.itan. (Patches for other database
vendors welcome)

=head1 COMMANDS

=over 

=item * delete  

Delete all invalid iTANs
L<App::iTan::Command::Delete>

=item * get     

Fetches selected iTAN
L<App::iTan::Command::Get>

=item * help    

Prints this usage information
L<App::iTan::Command::Help>

=item * import  

Imports a list of iTans into the database
L<App::iTan::Command::Import>

=item * info

Info about the selected iTAN
L<App::iTan::Command::info>

=item * list

List of all iTANs
L<App::iTan::Command::List>

=item * reset   

Reset unused iTANs
L<App::iTan::Command::Reset>

=back

=head1 SUPPORT

Please report any bugs or feature requests to 
C<app-itan@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=App::iTan>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    http://www.k-1.com

=head1 COPYRIGHT

App::iTan is Copyright (c) 2012 Maroš Kollár 
- L<http://www.k-1.com>

=head1 LICENCE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'Sponsored by Lehman Brothers Holdings Inc.';
