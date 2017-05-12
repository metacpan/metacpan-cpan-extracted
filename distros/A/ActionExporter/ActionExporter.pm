=head1 NAME

ActionExporter - Extends Exporter with the export_action() function, for use with the GCT::XSP::ActionTaglib module.

=head1 SYNOPSIS

    require ActionExporter;
    our @ISA = ("ActionExporter");

    ActionExporter::export_action("foo");

    sub foo_start{ #... }
    sub foo_end{ #... }

=head1 DESCRIPTION

Extends Exporter with the export_action() function. Calling ActionExporter::export_action("foo") exports the two subs 'foo_start' and 'foo_end' under a export tag 'foo'. This is usefull for creating an action Library as follows:

    package MyActionsLibrary;
    require ActionExporter;
    our @ISA = ("ActionExporter");

    ActionExporter::export_action("foo");
    sub foo_start{ return '';}
    sub foo_end{   return '';}

    ActionExporter::export_action("bar");
    sub bar_start{ return '';}
    sub bar_end{   return '';}

A taglib created using using ActionTaglib can then use the 'foo' actions by simply adding 'use MyActionLibrary qw(:foo);', for example:

    package MyTaglib;
    use GCT::XSP::ActionTaglib;
    @ISA = qw(use GCT::XSP::ActionTaglib;);
    our $tagactions;

    use MyActionLibrary qw(:foo);
    $tagactions->{tag1}=[{ -action => 'foo' }];

Actions exported using the export_action() command are also added to the 'allactions' export tag so a taglib could import all the actions from an action library with:

    use MyActionLibrary qw(:allactions);
    $tagactions->{tag1}=[{ -action => 'foo' }];
    $tagactions->{tag2}=[{ -action => 'bar' }];

=cut

use 5.006;
use strict;
use warnings;

package ActionExporter;
require Exporter;
our @ISA = ("Exporter");

our $VERSION = '0.02';
our $REVISION; $REVISION = '$Revision: 1.2 $';

# variables changed in the caller by export_action
# our @EXPORT_OK;
# our %EXPORT_TAGS;

sub export_action{
    my ($caller,undef,undef)=caller; 
    my $action = shift;
    my ($ex_tags,$ex_ok);
    {
	no strict;
	$ex_tags = \%{"${caller}::EXPORT_TAGS"};
	$ex_ok = \@{"${caller}::EXPORT_OK"};
    }

    if ($caller->can("$action" . '_start')) {
	push @{ $ex_tags->{$action} }, ("$action" . '_start');
    }
    if ($caller->can("$action" . '_end')) {
	push @{ $ex_tags->{$action} }, ("$action" . '_end');
    }
    if( $ex_tags->{$action} ){
	push @$ex_ok,                     @{ $ex_tags->{$action} };
	push @{ $ex_tags->{allactions} }, @{ $ex_tags->{$action} };
    }
}

1;

__END__

=head1 AUTHOR

Adam Griffiths, E<lt>adam@goldcrosstechnical.co.ukE<gt>

=head1 BUGS

None known, please report any to bugreport@goldcrosstechnical.co.uk

=head1 SEE ALSO

L<perl>,
L<Exporter>
L<GCT::XSP::ActionTaglib>

=head1 COPYRIGHT

Copyright (C) 2003, Adam Griffiths, Goldcross Technical. All Rights Reserved.

This Program is free software. You may copy or redistribute it under the same terms as Perl itself.

NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
