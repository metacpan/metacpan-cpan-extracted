package Apache::Icon;

use strict;
use DynaLoader ();

{
    no strict;
    $VERSION = '0.02';
    @ISA = qw(Apache);

    #avoid inheritance of AutoLoader::AUTOLOAD
    *dl_load_flags = DynaLoader->can('dl_load_flags');
    if ($ENV{MOD_PERL}) {
	(defined &bootstrap ? \&bootstrap : \&DynaLoader::bootstrap)->
	    (__PACKAGE__, $VERSION);
    }
}

1;
__END__

=head1 NAME

Apache::Icon - Lookup icon images

=head1 SYNOPSIS

    use Apache::Icon ();
    my $icon = Apache::Icon->new($subr);
    my $img = $icon->find || $icon->default;
    my $alt = $icon->alt;

=head1 DESCRIPTION

This module rips out the icon guts of mod_autoindex and provides a Perl
interface for looking up icon images.  The motivation is to piggy-back the
existing I<AddIcon> and related directives for mapping file extensions and
names to icons, while keeping things as small and fast as mod_autoindex 
does.

=head1 METHODS

=over 4

=item new

Create a new I<Apache::Icon> object with the given I<Apache::SubRequest>
object.  Example:

    for my $entry (sort $dh->read) {
	next if $entry eq '.';
	my $subr = $r->lookup_file($entry);
        my $icon = Apache::Icon->new($subr);
	...

=item find

Lookup icon image associated with the subrequest.

    my $img = $icon->find;

=item default

Lookup the default icon images.

    my $img = $icon->default; #DefaultIcon (unknown.gif)
    my $img = $icon->default("^^DIRECTORY^^"); #folder.gif
    my $img = $icon->default("^^BLANKICON^^"); #blank.gif

=item alt

Lookup the text alternative specified by the B<AddAlt> directive.

    my $alt = $icon->alt || $img;

=back

=head1 DIRECTIVES

Refer to the I<mod_autoindex> documentation for directives listed here
with no description.

=over 4

=item IconDouble

This directive can be set to I<On> or I<Off>.  The default is I<On> if
I<mod_autoindex> is configured with the server, I<Off> otherwise.
When the directive is I<On>, I<mod_icon> directive handlers will return
B<DECLINE_CMD> after processing which allows I<mod_autoindex> to also
handle the various I<Icon> and I<Alt> directives.

=item AddIcon

=item AddIconByType

=item AddIconByEncoding

=item AddAlt

=item AddAltByType

=item AddAltByEncoding

=item DefaultIcon

=back

=head1 SEE ALSO

Apache::AutoIndex(3)

=head1 AUTHOR

Doug MacEachern

C code based on mod_autoindex by the Apache Group
