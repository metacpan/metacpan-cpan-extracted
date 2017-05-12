package Bundle::OpenInteract;

# $Id: OpenInteract.pm,v 1.12 2003/04/08 01:21:22 lachoy Exp $

$Bundle::OpenInteract::VERSION = '1.11';

1;

__END__

=head1 NAME

Bundle::OpenInteract - Bundle to install all the pre-requisites for OpenInteract

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::OpenInteract'>

=head1 CONTENTS

Apache::Request (0.31)

Apache::Session (1.50)

Archive::Tar

Carp::Assert

Class::Accessor

Class::Date (1.00)

Class::Fields

Class::Singleton (1.03)

Compress::Zlib (1.08)

Digest::MD5

File::Copy

File::Basename

File::MMagic

File::Path
File::Spec

HTML::Entities (1.13)

HTTP::Request

Lingua::Stem

MIME::Lite (2.00)

Mail::RFC822::Address (0.3)

Mail::Sendmail (0.77)

Pod::POM (0.15)

Pod::Usage (1.12)

SPOPS (0.60)

Template (2.04)

Text::Sentence

OpenInteract

=head1 DESCRIPTION

Install all the modules needed for OpenInteract. A few of them have to
do with the package installer, but most are just for normal operation.

=head1 MORE INFORMATION

Sourceforge Project Home:

 http://sourceforge.net/projects/openinteract/

News, documentation and collaborative environment:

 http://openinteract.sourceforge.net/

=head1 AUTHOR

Chris Winters E<lt>chris@cwinters.comE<gt>
