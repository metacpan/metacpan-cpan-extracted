package Bundle::OpenInteract2;

# $Id: OpenInteract2.pm,v 1.3 2004/12/05 21:17:42 lachoy Exp $

$Bundle::OpenInteract2::VERSION = '1.03';

1;

__END__

=head1 NAME

Bundle::OpenInteract2 - Bundle to install all the pre-requisites for OpenInteract2

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::OpenInteract2'>

=head1 CONTENTS

Apache::Session (1.50)

Archive::Zip

Cache::FileCache

CGI::Cookie

Carp::Assert

Class::Accessor

Class::Factory (1.00)

Class::Fields

Class::Observable (1.00)

Class::Singleton (1.03)

DateTime (0.13)

DateTime::Format::Strptime (1.00)

Devel::StackTrace

Digest::MD5

Email::Valid

Exception::Class

File::Copy

File::DirSync (1.11)

File::MMagic

Getopt::Long (2.32)

HTML::Entities (1.13)

Lingua::Stem (0.50)

Locale::Maketext (1.06)

Log::Dispatch (2.00)

Log::Log4perl (0.34)

LWP::Simple

MIME::Lite (2.00)

Mail::RFC822::Address (0.3)

Mail::Sendmail (0.77)

Pod::POM (0.15)

SPOPS (0.87)

Template (2.04)

Test::MockObject (0.12)

Test::More (0.41)

Text::Sentence

URI

DBD::SQLite (0.25)

=head1 DESCRIPTION

Install all the modules needed for OpenInteract2, but not OI2 itself
until it is out of beta.

=head1 MORE INFORMATION

Sourceforge Project Home:

 http://sourceforge.net/projects/openinteract/

News, documentation and collaborative environment:

 http://www.openinteract.org/

=head1 AUTHOR

Chris Winters E<lt>chris@cwinters.comE<gt>
