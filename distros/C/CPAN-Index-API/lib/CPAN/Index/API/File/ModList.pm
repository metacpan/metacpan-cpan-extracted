package CPAN::Index::API::File::ModList;

our $VERSION = '0.008';

use strict;
use warnings;
use URI;
use Carp        qw(carp croak);
use Path::Class qw(file);
use namespace::autoclean;
use Moose;

with qw(
    CPAN::Index::API::Role::Writable
    CPAN::Index::API::Role::Readable
    CPAN::Index::API::Role::Clonable
    CPAN::Index::API::Role::HavingFilename
    CPAN::Index::API::Role::HavingGeneratedBy
);

has description => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'Package names found in directory $CPAN/authors/id/',
);

has modules => (
    is      => 'bare',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        module_count => 'count',
        modules      => 'elements',
    },
);

# lots of code from Parse::CPAN::Modlist here
sub parse {
    my ( $self, $content ) = @_;

    ### get rid of the comments and the code ###
    ### need a smarter parser, some people have this in their dslip info:
    # [
    # 'Statistics::LTU',
    # 'R',
    # 'd',
    # 'p',
    # 'O',
    # '?',
    # 'Implements Linear Threshold Units',
    # ...skipping...
    # "\x{c4}dd \x{fc}ml\x{e4}\x{fc}ts t\x{f6} \x{eb}v\x{eb}r\x{ff}th\x{ef}ng!",
    # 'BENNIE',
    # '11'
    # ],
    ### also, older versions say:
    ### $cols = [....]
    ### and newer versions say:
    ### $CPANPLUS::Modulelist::cols = [...]
    $content =~ s/.+}\s+(\$(?:CPAN::Modulelist::)?cols)/$1/s;

    ### split '$cols' and '$data' into 2 variables ###
    my ($ds_one, $ds_two) = split ';', $content, 2;

    ### eval them into existance ###
    my ($columns, $data, @modules, %args );

    $columns = eval $ds_one;
    croak "Error in eval of 03modlist.data source files: $@" if $@;

    $data = eval $ds_two;
    croak "Error in eval of 03modlist.data source files: $@" if $@;

    my %map = (
        modid       => 'name',
        statd       => 'development_stage',
        stats       => 'support_level',
        statl       => 'language_used',
        stati       => 'interface_style',
        statp       => 'public_license',
        userid      => 'authorid',
        chapterid   => 'chapterid',
        description => 'description',
    );

    if ( my @unknown_columns = grep { ! $map{$_} } @$columns ) {
        carp "Found unknown columns in 03modlist.data: "
             . join ', ', @unknown_columns;
    }

    foreach my $entry ( @$data ) {
        my %module;

        @module{@map{@$columns}} = @$entry;
        $module{chapterid} = int($module{chapterid});

        my @dslip = qw(
            development_stage
            support_level
            language_used
            interface_style
            public_license
        );

        undef $module{$_} for grep { $module{$_} eq '?' } @dslip;

        $module{dslip} = join '', map { defined $_ ? $_ : '?' } @dslip;

        push @modules, \%module;
    }

    $args{modules} = \@modules if @modules;

    return %args;
}

sub default_location { 'modules/03modlist.data.gz' }

__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::File::ModList - Interface to C<03modlist.data>.

=head1 SYNOPSIS

  my $modlist = CPAN::Index::File::ModList->parse_from_repo_uri(
    'http://cpan.perl.org'
  );

  foreach my $module ($modlist->modules) {
    ... # do something
  }

=head1 DESCRIPTION

This is a class to read and write C<03modlist.data>.

=head1 METHODS

=head2 modules

List of hashrefs containing module data. Each hashref has the following
structure.

=over

=item name

Module name, e.g. C<Foo::Bar>.

=item description

Short description of the module.

=item authorid

CPAN id of the module author.

=item chapterid

Number of the chapter under which the module is classified. Valid options are:

=over

=item 2 - Perl Core Modules

=item 3 - Development Support

=item 4 - Operating System Interfaces

=item 5 - Networking Devices IPC

=item 6 -Data Type Utilities

=item 7 - Database Interfaces

=item 8 - User Interfaces

=item 9 - Language Interfaces

=item 10 - File Names Systems Locking

=item 11 - String Lang Text Proc

=item 12 - Opt Arg Param Proc

=item 13 - Internationalization Locale

=item 14 - Security and Encryption

=item 15 - World Wide Web HTML HTTP CGI

=item 16 - Server and Daemon Utilities

=item 17 - Archiving and Compression

=item 18 - Images Pixmaps Bitmaps

=item 19 - Mail and Usenet News

=item 20 - Control Flow Utilities

=item 21 - File Handle Input Output

=item 22 - Microsoft Windows Modules

=item 23 - Miscellaneous Modules

=item 24 - Commercial Software Interfaces

=item 26 - Documentation

=item 27 - Pragma

=item 28 - Perl6

=item 99 - Not In Module list

=back

=item development_stage

Single character indicating the development stage of the module. Valid
options are:

=over

=item M - Mature (no rigorous definition)

=item R - Released

=item S - Standard, supplied with Perl 5

=item a - Alpha testing

=item b - Beta testing

=item c - Under construction but pre-alpha (not yet released)

=item i - Idea, listed to gain consensus or as a placeholder

=back

=item support_level

Single character indicating the type of support provided for the module.
Valid options are:

=over

=item a - Abandoned, the module has been abandoned by its author

=item d - Developer

=item m - Mailing-list

=item n - None known, try comp.lang.perl.modules

=item u - Usenet newsgroup comp.lang.perl.modules

=back

=item language_used

Single character indicating the programming languages used in the module.
Valid options are:

=over

=item + - C++ and perl, a C++ compiler will be needed

=item c - C and perl, a C compiler will be needed

=item h - Hybrid, written in perl with optional C code, no compiler needed

=item o - perl and another language other than C or C++

=item p - Perl-only, no compiler needed, should be platform independent

=back

=item interface_style

Single character indicating the interface of the module. Valid options are:

=over

=item O - Object oriented using blessed references and/or inheritance

=item f - plain Functions, no references used

=item h - hybrid, object and function interfaces available

=item n - no interface at all (huh?)

=item r - some use of unblessed References or ties

=back

=item public_license

Single character indicating the license under which the module is distributed.
Valid options are:

=over

=item a - Artistic license alone

=item b - BSD: The BSD License

=item g - GPL: GNU General Public License

=item l - LGPL: "GNU Lesser General Public License" (previously known as "GNU Library General Public License")

=item o - other (but distribution allowed without restrictions)

=item p - Standard-Perl: user may choose between GPL and Artistic

=back

=back

=head2 module_count

Number of modules indexed in the file.

=head2 filename

Name of this file - defaults to C<03modlist.data.gz>;

=head2 description

Short description of the file.

=head2 parse

Parses the file and returns its representation as a data structure.

=head2 default_location

Default file location - C<modules/03modlist.data.gz>.

=head1 METHODS FROM ROLES

=over

=item <CPAN::Index::API::Role::Readable/read_from_string>

=item <CPAN::Index::API::Role::Readable/read_from_file>

=item <CPAN::Index::API::Role::Readable/read_from_tarball>

=item <CPAN::Index::API::Role::Readable/read_from_repo_path>

=item <CPAN::Index::API::Role::Readable/read_from_repo_uri>

=item L<CPAN::Index::API::Role::Writable/tarball_is_default>

=item L<CPAN::Index::API::Role::Writable/repo_path>

=item L<CPAN::Index::API::Role::Writable/template>

=item L<CPAN::Index::API::Role::Writable/content>

=item L<CPAN::Index::API::Role::Writable/write_to_file>

=item L<CPAN::Index::API::Role::Writable/write_to_tarball>

=item L<CPAN::Index::API::Role::Clonable/clone>

=item L<CPAN::Index::API::Role::HavingFilename/filename>

=item L<CPAN::Index::API::Role::HavingGeneratedBy/generated_by>

=item L<CPAN::Index::API::Role::HavingGeneratedBy/last_generated>

=back

=cut

__DATA__
File:        [% $self->filename %]
Description: [% $self->description %]
Modcount:    [% $self->module_count %]
Written-By:  [% $self->generated_by %]
Date:        [% $self->last_generated %]

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
my $result = {};
my $primary = "modid";
for (@$CPAN::Modulelist::data){
my %hash;
@hash{@$CPAN::Modulelist::cols} = @$_;
$result->{$hash{$primary}} = \%hash;
}
$result;
}
$CPAN::Modulelist::cols = [
'modid',
'statd',
'stats',
'statl',
'stati',
'statp',
'description',
'userid',
'chapterid'
];

[%
    if ($self->module_count)
    {
        $OUT .= '$CPAN::Modulelist::data = [' . "\n";

        foreach my $module ($self->modules) {
            $OUT .= sprintf "[\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s'\n],\n",
                $module->{name},
                $module->{development_stage} ? $module->{development_stage} : '?',
                $module->{support_level}     ? $module->{support_level}     : '?',
                $module->{language_used}     ? $module->{language_used}     : '?',
                $module->{interface_style}   ? $module->{interface_style}   : '?',
                $module->{public_license}    ? $module->{public_license}    : '?',
                $module->{description},
                $module->{authorid},
                $module->{chapterid},
        }

        $OUT .= "];\n"
    }
    else
    {
        $OUT .= '$CPAN::Modulelist::data = [];' . "\n";
    }
%]
