package App::ZofCMS::Plugin::FileList;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use File::Glob (qw/bsd_glob/);

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{plug_file_list}
            or $config->conf->{plug_file_list};

    my %conf = (
        name    => 1,
        %{ delete $config->conf->{plug_file_list} || {} },
        %{ delete $template->{plug_file_list}     || {} },
    );

    return
        unless defined $conf{list};

    if ( not ref $conf{list} ) {
        $conf{list} = { plug_file_list => [ $conf{list} ] };
    }
    elsif ( ref $conf{list} eq 'ARRAY' ) {
        $conf{list} = { plug_file_list => $conf{list} };
    }

    keys %{ $conf{list} };
    while( my ( $t_key, $files ) = each %{ $conf{list} } ) {
        ref $files
            or $files = [ $files ];

        my @list;
        for ( @$files ) {
            substr($_, -1, 1) eq '/'
                or substr($_, -1, 1) eq '\\'
                or $_ .= '/';
            my @current_list = bsd_glob $_ . '*';
            push @list, $conf{re} ? ( grep /$conf{re}/, @current_list ) : @current_list;
        }
        $template->{t}{ $t_key } = [
            map +{
                path => $_,
                ( $conf{name} ? ( name => (split '/')[-1] ) : () ),
            }, @list,
        ];
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FileList - ZofCMS plugin to display lists of files

=head1 SYNOPSIS

In your Main Config file or ZofCMS template:

    plugins     => [ qw/FileList/ ],
    plug_file_list => {
        list => {
            list1 => 'pics',
            list2 => 'pics2',
        },
    },

In your L<HTML::Template> template:

    <ul>
    <tmpl_loop name='list1'>
        <li><a href="/<tmpl_var escape='html' name='path'>"><tmpl_var name='name'></a></li>
    </tmpl_loop>
    </ul>

    <ul>
    <tmpl_loop name='list2'>
        <li><a href="/<tmpl_var escape='html' name='path'>"><tmpl_var name='name'></a></li>
    </tmpl_loop>
    </ul>

=head1 DESCRIPTION

Module is a L<App::ZofCMS> plugin which provides means to display lists of files.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE OR ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/FileList/ ],

You would definitely want to add the plugin into the list of plugins to execute :)

=head2 C<plug_file_list>

    plug_file_list => {
        name => 0,
        re   => qr/[.]jpg$/i,
        list => {
            list1 => 'pics',
            list2 => [ qw/pics2 pics3/ ],
        },
    },

    plug_file_list => {
        list => [ qw/pics pics2/ ],
    },

    plug_file_list => {
        list => 'pics',
    },

You can specify the C<plug_file_list> first-level key in either Main Config File or ZofCMS
Template file. Specifying the same keys in both will lead to the ones set in ZofCMS Template
take precedence.

The C<plug_file_list> key takes a hashref as a value. Possible keys/values of that hashref
are as follows:

=head2 C<list>

    plug_file_list => {
        list => {
            list1 => 'pics',
            list2 => [ qw/pics2 pics3/ ],
        },
    },

    plug_file_list => {
        list => [ qw/pics pics2/ ],
    },

    plug_file_list => {
        list => 'pics',
    },

The C<list> key specifies the directories in which to search for files. The value of that
key can be either a hashref, arrayref or a scalar. If the value is not a hashref it will
be converted into a hashref as follows:

    plug_file_list => {
        list => 'pics', # a scalar
    },

    # same as

    plug_file_list => {
        list => [ 'pics' ], # arrayref
    },

    # same as

    # hashref with a key that has a scalar value
    plug_file_list => {
        list => {
            plug_file_list => 'pics',
        }
    },

    # same as

    # hashref with a key that has an arrayref value
    plug_file_list => {
        list => {
            plug_file_list => [ 'pics' ],
        }
    },

The hashref assigned to C<list> (or converted from other values) takes the following meaning:
the keys of that hashref are the names of the keys in C<{t}> ZofCMS Template special key
and the values are the lists (arrayrefs) of directories in which to search for files.
See SYNOPSIS section for some examples. Note that default C<{t}> key would be C<plug_file_list>
as is shown in conversion examples above.

=head2 C<re>

    plug_file_list => {
        re   => qr/[.]jpg$/i,
        list => 'pics',
    },

B<Optional>. The C<re> argument takes a regex as a value (C<qr//>). If specified only the files
that match the regex will be listed. B<By default> is not specified.

=head2 C<name>

    plug_file_list => {
        name => 0,
        list => 'foo',
    },

B<Optional>. Takes either true or false values,
specifies whether or not to create the C<name> C<< <tmpl_var name=""> >> in the
output. See C<HTML::Template TEMPLATES> section below. B<Defaults to:> C<1> (*do* create)

=head1 HTML::Template TEMPLATES

In HTML::Template templates you'd show the file lists in the following fashion:

    <ul>
    <tmpl_loop name='plug_file_list'>
        <li><a href="/<tmpl_var escape='html' name='path'>"><tmpl_var name='name'></a></li>
    </tmpl_loop>
    </ul>

The name of the C<< <tmpl_loop name=""> >> is what you specified (directly or indirectly)
as keys in the C<list> hashref (see above). Inside the loop there are two
C<< <tmpl_var name=""> >> that you can use:

=head2 C<< <tmpl_var name='path'> >>

The C<< <tmpl_var name='path'> >> will contain the path to the file, that is the directory
you specified . '/' . file name.

=head2 C<< <tmpl_var name='name'> >>

The C<< <tmpl_var name='path'> >> (providing the C<name> key in C<plug_file_list> hashref
is set to a true value) will contain just the filename of the file.

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