package App::ZofCMS::Plugin::DataToExcel;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use Spreadsheet::DataToExcel;

sub _key { 'plug_data_to_excel' }
sub _defaults {
    return (
        trigger     => 1,
        filename    => 'ExcelData.xls',
        no_exit     => 0,
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    for ( qw/trigger  data/ ) {
        $conf->{$_} = $conf->{$_}->( $t, $q, $config )
            if ref $conf->{$_} eq 'CODE';
    }

    return
        unless $conf->{trigger}
            and $conf->{data};

    my $excel = Spreadsheet::DataToExcel->new;

    my $output;
    open my $fh, '>', \$output
        or do {
            $t->{t}{plug_data_to_excel_error} = $!;
            return;
        };

    unless ( $excel->dump( $fh, @$conf{qw/data  options/} ) ) {
        $t->{t}{plug_data_to_excel_error} = $excel->error;
        return;
    }

    print "Content-Disposition: inline; filename=$conf->{filename}\n";
    print "Content-type: application/vnd.ms-excel\n\n";
    print $output;
    exit
        unless $conf->{no_exit};
}

1;

=head1 NAME

App::ZofCMS::Plugin::DataToExcel - ZofCMS plugin to output data as an Excel file

=head1 SYNOPSIS

    plugins => [
        qw/DataToExcel/,
    ],

    plug_data_to_excel => {
        data => [
            [ qw/Foo  Bar  Baz/ ],
            [ qw/Foo1 Bar1 Baz1/ ],
            [ qw/Foo2 Bar2 Baz2/ ],
        ],

        # this argument is optional; by default not specified
        options     => {
            text_wrap           => 1,
            calc_column_widths  => 1,
            width_multiplier    => 1,
            center_first_row    => 1,
        },

        # arguments below are optional; defaults are shown
        trigger     => 1,
        filename    => 'ExcelData.xls',
        no_exit     => 0,
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to easily
export an arrayref of arrayrefs (your data) as an Excel file presented
to the user.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>. Familarity with
L<Spreadsheet::DataToExcel> would be helpful.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/DataToExcel/ ],

B<Mandatory>. You need to include the plugin in the list of
plugins to execute.

=head2 C<plug_data_to_excel>

    plug_data_to_excel => {
        data => [
            [ qw/Foo  Bar  Baz/ ],
            [ qw/Foo1 Bar1 Baz1/ ],
            [ qw/Foo2 Bar2 Baz2/ ],
        ],

        # this argument is optional; by default not specified
        options     => {
            text_wrap           => 1,
            calc_column_widths  => 1,
            width_multiplier    => 1,
            center_first_row    => 1,
        },

        # arguments below are optional; defaults are shown
        trigger     => 1,
        filename    => 'ExcelData.xls',
        no_exit     => 0,
    },

    # or
    plug_data_to_excel => sub {
        my ( $t, $q, $config ) = @_;
        return $hashref_to_assign_to_this_key_instead_of_subref;
    },

B<Mandatory>. Takes either a hashref or a subref as a value.
If subref is specified, its return value will be assigned to
C<plug_data_to_excel> as if it were already there. If sub returns an
C<undef> or an empty list, then plugin will stop further processing. The
C<@_> of the subref will contain C<$t>, C<$q>, and C<$config>
(in that order), where C<$t> is ZofCMS Template hashref, C<$q> is
query parameter hashref, and C<$config> is L<App::ZofCMS::Config>
object. Possible keys/values for the hashref are as follows:

=head3 C<data>

    plug_data_to_excel => {
        data => [
            [ qw/Foo  Bar  Baz/ ],
            [ qw/Foo1 Bar1 Baz1/ ],
            [ qw/Foo2 Bar2 Baz2/ ],
        ],
    ...

    plug_data_to_excel => {
        data => sub {
            my ( $t, $q, $config ) = @_;
            return $arrayref_to_assign_to_the_key_instead_of_this_subref;
        },
    ...

B<Mandatory>. If not specified, plugin will not execute. Takes an
arrayref or a subref as a value. If a subref is specified, it must
return either an C<undef> or an empty list, in which case the plugin
will not run, or an arrayref that will be assigned to C<data> as
if it were there instead of the subref.

If subref is specified, the C<@_> of the subref will contain
C<$t>, C<$q>, and C<$config> (in that order), where C<$t> is ZofCMS
Template hashref, C<$q> is query parameter hashref, and C<$config> is
L<App::ZofCMS::Config> object.

The arrayref must be in the same format as the I<second> argument
of L<Spreadsheet::DataToExcel>'s C<dump()> method.

=head3 C<options>

    plug_data_to_excel => {
        options => {
            text_wrap           => 1,
            calc_column_widths  => 1,
            width_multiplier    => 1,
            center_first_row    => 1,
        },
    ...

B<Optional>. Takes a hashref of arguments that specify how to format
the Excel file. See the I<third> argument for
L<Spreadsheet::DataToExcel>'s C<dump()>'s method for details.
B<By default is not specified>

=head3 C<trigger>

    plug_data_to_excel => {
        trigger => 1,
    ...

    plug_data_to_excel => {
        trigger => sub {
            my ( $t, $q, $config ) = @_;
            return $actual_value_for_trigger;
        },
    ...

B<Optional>. Takes either true or false values, or a subref that
returns either true or false values. Plugin will run only if
C<trigger> is set to a true value. If set to a subref, the C<@_> of the
subref will contain C<$t>, C<$q>, and C<$config> (in that order), where
C<$t> is ZofCMS Template hashref, C<$q> is query parameter hashref, and
C<$config> is L<App::ZofCMS::Config> object. B<Defaults to:> C<1>

=head3 C<filename>

    plug_data_to_excel => {
        filename => 'ExcelData.xls',
    ...

B<Optional>. Takes a string as a value that specifies the filename
that the browser will propose to the user (when saving your Excel file).
B<Defaults to:> C<ExcelData.xls>

=head3 C<no_exit>

    plug_data_to_excel => {
        no_exit => 0,
    ...

B<Optional>. Takes either true or false values. When plugin
finishes outputting the Excel file to the user, it will call
C<exit()>, unless C<no_exit> is set to a true value. Should that be
the case, it is your responsibility to call C<exit()> at a later time;
although, OpenOffice didn't seem to mind extraneous HTML code added
to the Excel file. B<Defaults to:> C<0>

=head1 HTML::Template TEMPLATE VARIABLES

=head2 C<plug_data_to_excel_error>

    <tmpl_if name='plug_data_to_excel_error'>
        <tmpl_var escape='html' name='plug_data_to_excel_error'>
    </tmpl_if>

Should an error occur (e.g. when you give the plugin invalid
C<data> argument), the plugin will place the description of
the error into C<plug_data_to_excel_error> key of C<{t}> ZofCMS
Template special key.

=head1 REQUIRED MODULES

The plugin requires the following modules/versions

    App::ZofCMS::Plugin::Base => 0.0111,
    Spreadsheet::DataToExcel  => 0.0103,

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut