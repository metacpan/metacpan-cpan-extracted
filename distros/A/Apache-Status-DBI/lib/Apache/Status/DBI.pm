package Apache::Status::DBI;

use warnings;
use strict;
use Carp;

our $VERSION = '1.012'; # $Id: DBI.pm 9845 2007-08-16 14:13:30Z timbo $

use DBI ();

# if MOD_PERL_API_VERSION env var exists then use it to determine mod_perl v1 or v2
# if not, then assume mod_perl v2 if we can load mod_perl2 module
use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION})
        ? ($ENV{MOD_PERL_API_VERSION} >= 2)
        : eval { require mod_perl2 };

BEGIN {
    if (MP2) {
        require mod_perl2;
        require Apache2::Module;
        *escape_html = sub {
            my $s = shift;
            $s =~ s/&/&amp;/g;
            $s =~ s/</&lt;/g;
            $s =~ s/>/&gt;/g;
            return $s;
        }
    }
    else {
        require Apache;
        require Apache::Util;
        Apache::Util->import(qw(escape_html));
    }
}

my %apache_status_menu_items = (
    DBI_handles => [ 'DBI Handles', \&apache_status_dbi_handles ],
);
my $apache_status_class;
if (MP2) {
    $apache_status_class = "Apache2::Status" if Apache2::Module::loaded('Apache2::Status');
}
elsif ($INC{'Apache.pm'}                       # is Apache.pm loaded?
       and Apache->can('module')               # really?
       and Apache->module('Apache::Status')) { # Apache::Status too?
       $apache_status_class = "Apache::Status";
}
if ($apache_status_class) {
    while ( my ($url, $menu_item) = each %apache_status_menu_items ) {
        $apache_status_class->menu_item($url => @$menu_item);
    }
}


=pod

=over 1

=item B<apache_status_dbi_handles>

Displays all handles and associated information via the Apache::Status
webpages in a running httpd mod_perl enabled server.

=back

=cut
sub apache_status_dbi_handles {
    my($r, $q) = @_;
    my @s = ("<pre>",
        "<b>DBI $DBI::VERSION - Drivers, Connections and Statements</b><p>\n",
    );

    my %drivers = DBI->installed_drivers();
    push @s, sprintf("%d drivers loaded: %s<p>", scalar keys %drivers, join(", ", keys %drivers));
    
    while ( my ($driver, $h) = each %drivers) {
        my $version = do { no strict; ${"DBD::${driver}::VERSION"} || 'undef' }; ## no critic
        my @children = grep { defined } @{$h->{ChildHandles}};
        
        push @s, sprintf "<hr><b>DBD::$driver</b>  <font size=-2 color=grey>version $version,  %d dbh (%d cached, %d active)  $h</font>\n\n",
            scalar @children, scalar keys %{$h->{CachedKids}||{}}, $h->{ActiveKids};
        
        @children = sort { ($a->{Name}||"$a") cmp ($b->{Name}||"$b") } @children;
        push @s, _apache_status_dbi_handle($_, 1) for @children;
    }
    
    push @s, "<hr>";
    push @s, "<font size=-2 color=grey>".__PACKAGE__." $VERSION</font>";
    push @s, "</pre>\n";
    return \@s;
}



sub _apache_status_dbi_handle {
    my ($h, $level) = @_;
    my $pad = "    " x $level;
    my $type = $h->{Type};
    my @children = grep { defined } @{$h->{ChildHandles}};
    my @boolean_attr = qw(
        Active Executed RaiseError PrintError ShowErrorStatement PrintWarn
        CompatMode InactiveDestroy HandleError HandleSetErr
        ChopBlanks LongTruncOk TaintIn TaintOut Profile);
    my @scalar_attr = qw(
        ErrCount TraceLevel FetchHashKeyName LongReadLen
    ); 
    my @scalar_attr2 = qw();

    my @s;
    if ($type eq 'db') {
        push @s, sprintf "DSN \"<b>%s</b>\"  <font size=-2 color=grey>%s</font>\n", $h->{Name}, $h;
        @children = sort { ($a->{Statement}||"$a") cmp ($b->{Statement}||"$b") } @children;
        push @boolean_attr, qw(AutoCommit);
        push @scalar_attr,  qw(Username);
    }
    else {
        push @s, sprintf "    sth  <font size=-2 color=grey>%s</font>\n", $h;
        push @scalar_attr2, qw(NUM_OF_PARAMS NUM_OF_FIELDS CursorName);
    }

    push @s, sprintf "%sAttributes: %s\n", $pad,
        join ", ", grep { $h->{$_} } @boolean_attr;
    push @s, sprintf "%sAttributes: %s\n", $pad,
        join ", ", map { "$_=".DBI::neat($h->{$_}) } @scalar_attr;
    if (my $sql = escape_html($h->{Statement} || '')) {
        $sql =~ s/\n/ /g;
        push @s, sprintf "%sStatement: <b>%s</b>\n", $pad, $sql;
        my $ParamValues = $type eq 'st' && $h->{ParamValues};
        push @s, sprintf "%sParamValues: %s\n", $pad,
                join ", ", map { "$_=".DBI::neat($ParamValues->{$_}) } sort keys %$ParamValues
            if $ParamValues && %$ParamValues;
    }
    push @s, sprintf "%sAttributes: %s\n", $pad,
        join ", ", map { "$_=".DBI::neat($h->{$_}) } @scalar_attr2
        if @scalar_attr2;
    push @s, sprintf "%sRows: %s\n", $pad, $h->rows
        if $type eq 'st' || $h->rows != -1;
    if (defined( my $err = $h->err )) {
        push @s, sprintf "%s%s %s %s\n", $pad,
            ($err ? "Error" : length($err) ? "Warning" : "Information"),
            $err, escape_html($h->errstr);
    }
    push @s, sprintf "    sth: %d (%d cached, %d active)\n",
        scalar @children, scalar keys %{$h->{CachedKids}||{}}, $h->{ActiveKids}
        if @children;
    push @s, "\n";

    push @s, map { _apache_status_dbi_handle($_, $level + 1) } @children;

    return @s;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Apache::Status::DBI - Show status of all DBI database and statement handles

=head1 VERSION

This document describes Apache::Status::DBI $Id: DBI.pm 9845 2007-08-16 14:13:30Z timbo $


=head1 SYNOPSIS

    use Apache::Status;
    use Apache::Status::DBI;
  
=head1 DESCRIPTION

A plugin for Apache::Status that adds a 'DBI handles' menu item to the Apache::Status page.

The DBI handles menu item leads to a page that shows all the key information
for all the drivers, database handles and statement handles that currently
exist within the process.

=head1 CONFIGURATION

The Apache::Status module must be loaded before Apache::Status::DBI.

=head1 DEPENDENCIES

DBI and Apache::Status

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-apache-status-dbi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Add links to drill-down to extra level of detail for a handle.

Turn on/off profiling for a handle?

Integrate with Apache::DBI?

=head1 AUTHOR

Tim Bunce  L<http://www.linkedin.com/in/timbunce>

Implemented while I was working on DBD::Gofer and DBI::Gofer::Transport::mod_perl
for L<http://Shopzilla.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Tim Bunce C<< <Tim.Bunce@pobox.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
