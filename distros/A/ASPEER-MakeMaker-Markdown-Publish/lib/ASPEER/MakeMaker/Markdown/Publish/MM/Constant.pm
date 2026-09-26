#
#  This file is part of ASPEER::MakeMaker::Markdown::Publish.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

package ASPEER::MakeMaker::Markdown::Publish::MM::Constant;

use strict qw(vars);
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

$VERSION='1.003';

my $local_fn=abs_path(__FILE__).'.local';

%Constant=(
    MM_PREFIX => 'PUBLISH',

    TEMPLATE_POSTAMBLE_FN =>
        File::Spec->catfile(dirname(abs_path(__FILE__)), 'postamble.inc'),

    PUBLISH_PM => 'ASPEER::MakeMaker::Markdown::Publish::MM',

    PUBLISH_PM_ARGV => join(',', qw[
        "$(NAME)"
        "$(NAME_SYM)"
        "$(DISTNAME)"
        "$(DISTVNAME)"
        "$(VERSION)"
        "$(VERSION_SYM)"
        "$(VERSION_FROM)"
        "$(LICENSE)"
        "$(AUTHOR)"
        "$(TO_INST_PM)"
        "$(EXE_FILES)"
        "$(DIST_DEFAULT_TARGET)"
        "$(SUFFIX)"
        "$(ABSTRACT_FROM)"
        "$(PUBLISH_CONFIG)"
    ]),

    %{do($local_fn) || {}},
    %{do(glob(sprintf('~/.%s.local', __PACKAGE__))) || {}}
);

require Exporter;
@ISA=qw(Exporter);
{
    no warnings qw(once);
    foreach (keys(%Constant)) {${$_}=$Constant{$_}}
}
@EXPORT=map {'$'.$_} keys(%Constant);
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);

1;

__END__

=begin markdown

# NAME

ASPEER::MakeMaker::Markdown::Publish::MM::Constant - Makefile target constants

# DESCRIPTION

Defines the private `PUBLISH_*` macro namespace, bundled postamble template,
target dispatcher module, and fixed MakeMaker argument list used by
`ASPEER::MakeMaker::Markdown::Publish`.

The final argument is `PUBLISH_CONFIG`, the Base64-encoded JSON value derived
from `META_MERGE.x_documentation.publish`.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Publish.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

ASPEER::MakeMaker::Markdown::Publish::MM::Constant - Makefile target constants


=head1 DESCRIPTION

Defines the private C<PUBLISH_*> macro namespace, bundled postamble template,
target dispatcher module, and fixed MakeMaker argument list used by
C<ASPEER::MakeMaker::Markdown::Publish>.

The final argument is C<PUBLISH_CONFIG>, the Base64-encoded JSON value derived
from C<META_MERGE.x_documentation.publish>.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
