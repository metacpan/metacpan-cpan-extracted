package Bundle::SafeBrowsing;
our $VERSION = '1.01';
1;

__END__
=head1 NAME

Bundle::SafeBrowsing - SpamAssassin plugin that scores messages by looking up
the URIs they contain in Google's SafeBrowsing tables. See
L<http://code.google.com/apis/safebrowsing/>.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::SafeBrowsing'>

=head1 CONTENTS

Net::Google::SafeBrowsing::Blocklist            - Blocklist lookups
Net::Google::SafeBrowsing::UpdateRequest        - Blocklist updates
Mail::SpamAssassin::Plugin::GoogleSafeBrowsing  - SpamAssassin plugin

=head1 DESCRIPTION

See L<Mail::SpamAssassin::Plugin::GoogleSafeBrowsing> for configuration
requirements.

This Bundle is a wrapper for the SpamAssassin plugin module and its
dependencies.

=head1 SEE ALSO

L<Mail::SpamAssassin::Plugin::GoogleSafeBrowsing>
L<http://search.cpan.org/~danborn/>

=head1 AUTHOR

Daniel Born, E<lt>danborn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Daniel Born

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
