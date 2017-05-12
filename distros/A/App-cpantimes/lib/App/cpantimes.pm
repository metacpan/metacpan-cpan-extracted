package App::cpantimes;
our $VERSION = "1.502101";

=encoding utf8

=head1 NAME

App::cpantimes - get, unpack, build, install and report on modules from CPAN

=head1 SYNOPSIS

    cpant Module

Run C<cpant -h> or C<perldoc cpant> for more options.

=head1 DESCRIPTION

C<cpant> is a fairly trivial fork of L<cpanm>, adding support for
submitting reports to the CPAN testers service.

=head1 SEE ALSO

This is severely based on L<App::cpanminus>, so see that for help,
credits, etc.

=head1 COPYRIGHT

Copyright 2012-2013 Toby Inkster.

The standalone executable contains the following modules embedded.

=over 4

=item L<App::cpanminus::script> Copyright 2010- Tatsuhiko Miyagawa

=item L<CPAN::DistnameInfo> Copyright 2003 Graham Barr

=item L<Parse::CPAN::Meta> Copyright 2006-2009 Adam Kennedy

=item L<local::lib> Copyright 2007-2009 Matt S Trout

=item L<HTTP::Tiny> Copyright 2011 Christian Hansen

=item L<Module::Metadata> Copyright 2001-2006 Ken Williams. 2010 Matt S Trout

=item L<version> Copyright 2004-2010 John Peacock

=item L<JSON::PP> Copyright 2007−2011 by Makamaka Hannyaharamitu

=item L<CPAN::Meta> Copyright (c) 2010 by David Golden and Ricardo Signes

=item L<Try::Tiny> Copyright (c) 2009 Yuval Kogman

=item L<parent> Copyright (c) 2007-10 Max Maischein

=item L<Version::Requirements> copyright (c) 2010 by Ricardo Signes

=item L<CPAN::Meta::YAML> copyright (c) 2010 by Adam Kennedy

=back

=head1 LICENSE

Same as Perl.

=cut

1;
