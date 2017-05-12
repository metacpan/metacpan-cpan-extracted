package Bundle::Email;

use strict;

use vars qw{$VERSION};
BEGIN {
  $VERSION = '0.044';
}

1;

__END__

=head1 NAME

Bundle::Email - (DEPRECATED) you want Task::Email::PEP::NoStore

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::Email'

=head1 CONTENTS

Email::Address           - An email address

Email::MIME::Encodings   - Profiling tool

Email::MIME::ContentType - Another profiler

Email::MessageID         - A message ID

Email::Simple            - THE core Email module

Email::Date              - Parse and generate dates

Module::Pluggable        - Needed by Email::Abstract

Email::Abstract          - Email conversion and compatibility

Email::MIME              - MIME-based emails

Email::Simple::Creator   - Create simple emails

Email::MIME::Modifier    - Modify MIME emails

Email::MIME::Creator     - Create MIME emails

Net::SMTP                - For Email::Send::SMTP, the most common after Email::Send::Sendmail

Email::Send              - Send emails

Email::Send::Test        - Testing applications that use Email::Send

Email::FolderType        - Determine the type of a mail folder

Email::FolderType::Net   - Determine the type of mail folder for Net-based protocols

Email::LocalDelivery     - Deliver an email locally

Email::Folder            - Read all the emails in a folder

File::Type               - Used by Email::Stuff for file attachments

File::Slurp              - Used by Email::Stuff for file attachments

Email::Stuff             - Quickly generate and send emails

=head1 DESCRIPTION

Email:: distributions are intended to be small and tight, with a specific
purpose, and easily installed and loaded only as the bits are needed.

Which means that there's a whole bunch of them, all seperate.

Bundle::Email installs pretty much all of the main Email modules that don't
have giant cascading dependencies, like L<Email::Store> (which is a
L<Class::DBI>-based thing).

=head1 PERL EMAIL PROJECT

This bundle is maintained by the Perl Email Project.

  http://emailproject.perl.org/wiki/Bundle::Email

=head1 SEE ALSO

=over 4

=item * L<Task::Email::PEP::All>

=item * L<Task::Email::PEP::NoStore>

=back

=head1 SUPPORT

All bugs should be filed via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bundle%3A%3AEmail>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Ricardo SIGNES (Maintainer), C<rjbs@cpan.org>

=head1 COPYRIGHT

This code is copyright (C) 2004-2006, Adam Kennedy and Ricardo SIGNES. It is
released under the same terms as perl itself. No claims are made, here, as to
the copyrights of the software pointed to by this bundle.

=cut
