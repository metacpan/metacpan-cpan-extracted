package Bundle::MyLibrary;

$VERSION = '0.05';

1;

__END__

=head1 NAME 

Bundle::MyLibrary - MyLibrary Module Dependencies

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::MyLibrary>

=head1 DESCRIPTION

These are Perl dependencies for the MyLibrary portal software.
L<http://dewey.library.nd.edu/mylibrary/>

After installing you may get a report that there were some problems 
installing certain modules. Before reporting them make sure that they 
haven't installed by:

    perl -MMIME::Base64 -e 1

This will test to make sure the MIME::Base64 package is available. Substitute 
the name of any modules that were reported failed. If you have trouble
please write to the mylib-dev mailing list. Subscription details are 
available at http://dewey.library.nd.edu/mylibrary/mailing-list.shtml

=head1 CONTENTS

CGI

DBI

Pod::Parser

Data::ShowTable

MIME::Base64

DBD::mysql

URI

HTML::Parser

Bundle::libnet

LWP

Digest

Digest::MD5

MIME::Decoder::Base64

IO::Stringy

MIME::Parser - to grab MIME-tools

Mail::Send - to grab MailTools

Time::CTime - to grab Time-modules

=head1 TODO

=over 4

=item * Include version dependencies?

=back

=head1 AUTHOR

Ed Summers e<lt>ehs@pobox.come<gt>

