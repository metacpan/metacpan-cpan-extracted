package Catalyst::Plugin::Perlinfo;

use HTML::Perlinfo;
use HTML::Perlinfo::General;

our $VERSION = '0.01';

sub finalize_error {
    my $c = shift;

    $c->next::method(@_); 

    my $perlinfo = HTML::Perlinfo->new(htmlstart=>0);
    my $perlinfo_html = $perlinfo->print_htmlhead();
    $perlinfo_html .= print_general();
    delete $INC{'HTML/Perlinfo.pm'};
    $perlinfo_html .= print_thesemodules('loaded',[values %INC]);
    $perlinfo_html .= print_variables();

    if ( $c->debug ) {

        my $html = qq{
            <style type="text/css">
                div.infocolor {
                    background-color: #eee;
                    border: 1px solid #575;
                }
                div#infowidth table {
                    width: 100%;
                }
                div#infowidth th, td {
                    padding-right: 1.5em;
                    text-align: left;
                }
                div#infowidth .line {
                    color: #000;
                    font-weight: strong;
                }
            </style>
            <div class="infocolor error">
                <div id="infowidth">
		 	$perlinfo_html
		</div>
	    </div>
        };

        $c->res->{body} =~ s{<div class="infos">}{$html<div class="infos">};
    }
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Perlinfo - Display HTML::Perlinfo on the debug screen

=head1 SYNOPSIS

    use Catalyst qw/-Debug Perlinfo/;

=head1 DESCRIPTION

This plugin will enhance the standard Catalyst debug screen by including
a large amount of information about your Perl installation in HTML. 
So far, this includes information about Perl compilation options, the Perl 
version, server information and environment, HTTP headers, OS version 
information, Perl modules, and more.

L<HTML::Perlinfo> generates this useful information. 

This plugin is only active in -Debug mode.

=head1 SEE ALSO

L<Catalyst>
L<HTML::Perlinfo>

=head1 AUTHORS

Mike Accardo, <accardo@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2016
This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
