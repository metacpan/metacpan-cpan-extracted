package Dancer::Plugin::DictionaryCheck;

use 5.006;
use strict;
use Dancer ':syntax';
use Dancer::Plugin;

=head1 NAME

Dancer::Plugin::DictionaryCheck 

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Allows a case insensive search of a given string against a given dictionary.

    use Dancer::Plugin::DictionaryCheck;

    get '/ok_for_scrabble' => sub {  
        return dictionary_check( params->{word} ) ? "yes" : "no";
    };

    get '/change_dictionary' => sub {
        return dictionary_load( params->{file} ) ? "Loaded" : "Error";
    };

By default makes use /usr/share/dict/words which is present in standard debian
images.

=cut

my %DICT;

# Load a default dictionary when Dancer starts.
sub INIT {
    my $default_dict = '/usr/share/dict/words';
    
    Dancer::Plugin::DictionaryCheck::_load_dict($default_dict)
        or warning <<NODEFAULTDICT;
The Default dictionary (/usr/share/dict/words) could not be loaded, 
Please use dictionary_load to specify a dictionary to use before attempting to
use dictionary_check.
NODEFAULTDICT

};

=head1 Dancer Keywords

=head2 dictionary_load

Reloads the stored dictionary with the words from the supplied filename.
Returns false if said file doesn't exists and is not a regular file.

=cut

register 'dictionary_load' => sub {

    # Dancer 2 keywords receive a reference to the DSL object as a first param,
    # So if we're running under D2, we need to make sure we don't pass that on
    # to the route gathering code.
    shift if Scalar::Util::blessed($_[0]) && $_[0]->isa('Dancer::Core::DSL');
    my $dict_file = shift;

    return _load_dict($dict_file);
};

=head2 dictionary_check 

Checks the supplied string against the words in the loaded dictionary.

Returns 1 if present, 0 if it's not!  Simples!!

=cut

register 'dictionary_check' => sub {
    # Check we have a dictionary with some content
    if (!%Dancer::Plugin::DictionaryCheck::DICT) {
        warning( "Dictionary is empty" );
        return 0;
    }
    return 0 if (!$_[0]);
    return exists $Dancer::Plugin::DictionaryCheck::DICT{ lc $_[0] };
};


# OK, now we need to register this plugin with Dancer.
register_plugin( for_versions => [ qw( 1 2 ) ] );


# Loads specified dictionary file into the Plugin memspace.

sub _load_dict {
    my $file = shift;

    if ( !$file || !-e $file || !-f _ ) {
        warning( "Given file does not exist or is not a regular file." );
        return 0;
    }

    open my $dict_fh, '<', $file or do {
        warning( "Unable to open dictionary file for reading." );
        return 0;
    };
    
    # Bin the old dictionary
    %Dancer::Plugin::DictionaryCheck::DICT = ();

    # Load the dictionary and bin the newlines.
    while (<$dict_fh>) {
        chomp; 
        $Dancer::Plugin::DictionaryCheck::DICT{ lc $_ } = 1;
    }
    close $dict_fh;

    return 1;
}

=head1 AUTHOR

Ross Hayes, C<< <ross at abablabab.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-dictionarycheck at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-DictionaryCheck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::DictionaryCheck


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-DictionaryCheck>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-DictionaryCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-DictionaryCheck>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-DictionaryCheck/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ross Hayes.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dancer::Plugin::DictionaryCheck
