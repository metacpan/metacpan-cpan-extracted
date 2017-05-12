package Bundle::Delivery;

$VERSION = '0.03';

1;

__END__

=head1 NAME

Bundle::Delivery - Modules required to run the Delivery and/or Tapestry web-publishing applications

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::Delivery'

=head1 DESCRIPTION

This bundle provides an easy way to install all the modules used by the web-publishing and community-management application Delivery, and its more esoteric online-story-weaving sibling tapestry.

Many of these modules have dependencies, of course. You must have mod_perl already installed, for a start, to make full use of the Template Toolkit you may want to install some of its optional modules.

=head1 CONTENTS

Apache::Constants - Constants useful in dealing with apache requests

Apache::Request - Generate compiler and linker flags for libapreq

Apache::Util - Interface to fast Apache C util functions (used here for escaping, mostly)

Class::DBI::Factory - Application skeleton for Delivery.

Date::Calc - useful date manipulation

Date::Simple - useful date presentation and comparison

Email::Send - creates and sends email messages in a nice simple way

Email::Valid - checks email addresses for well-formedness and MX availability

File::Headerinfo - reads media file headers to extract dimensions and duration

File::NCopy - deep-copies directories. only used by installer in delivery

HTML::Entities - provides encoding and decoding of html entities, and a useful list

HTML::TagFilter - a fine-grained rule-based remover of html tags

Imager - handles all image-manipulation. make sure you have libgif, libjpeg and libpng in sensible places first.

Template - he's a big boy but he's clever.

Term::Prompt - nice interface for command-line interrogation. Only used for the install script here.

Text::CSV - reads and manipulates CSV data

=head1 SEE ALSO

For more about the charms and uses of delivery and tapestry, see www.spanner.org/software/

=head1 AUTHOR

William Ross <wross@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by William Ross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
