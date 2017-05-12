package App::Software::License; # git description: v0.10-4-g9e7e1ff
# ABSTRACT: Command-line interface to Software::License
# KEYWORDS: license licence LICENSE generate distribution build tool

our $VERSION = '0.11';

use Moo 1.001000;
use MooX::Options;
use File::HomeDir;
use File::Spec::Functions qw/catfile/;
use Module::Runtime qw/use_module/;
use Software::License;
use Config::Any;

use namespace::autoclean 0.16 -except => [qw/_options_data _options_config/];

#pod =head1 SYNOPSIS
#pod
#pod     software-license --holder 'J. Random Hacker' --license Perl_5 --type notice
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a command-line interface to Software::License. It can be
#pod used to easily produce license notices to be included in other documents.
#pod
#pod All the attributes documented below are available as command-line options
#pod through L<MooX::Options> and can also be configured in
#pod F<$HOME/.software_license.conf> through L<Config::Any>.
#pod
#pod =cut

#pod =attr holder
#pod
#pod Name of the license holder.
#pod
#pod =cut

option holder => (
    is       => 'ro',
    required => 1,
    format   => 's',
    doc => '',
);

#pod =attr year
#pod
#pod Year to be used in the copyright notice.
#pod
#pod =cut

option year => (
    is     => 'ro',
    format => 'i',
    doc => '',
);

#pod =attr license
#pod
#pod Name of the license to use. Must be the name of a module available under the
#pod Software::License:: namespace. Defaults to Perl_5.
#pod
#pod =cut

option license => (
    is      => 'ro',
    default => 'Perl_5',
    format  => 's',
    doc => '',
);

#pod =attr type
#pod
#pod The type of license notice you'd like to generate. Available values are:
#pod
#pod B<* notice>
#pod
#pod This method returns a snippet of text, usually a few lines, indicating the
#pod copyright holder and year of copyright, as well as an indication of the license
#pod under which the software is distributed.
#pod
#pod B<* license>
#pod
#pod This method returns the full text of the license.
#pod
#pod =for :stopwords fulltext
#pod
#pod B<* fulltext>
#pod
#pod This method returns the complete text of the license, preceded by the copyright
#pod notice.
#pod
#pod B<* version>
#pod
#pod =for :stopwords versioned
#pod
#pod This method returns the version of the license.  If the license is not
#pod versioned, this returns nothing.
#pod
#pod B<* meta_yml_name>
#pod
#pod This method returns the string that should be used for this license in the CPAN
#pod META.yml file, or nothing if there is no known string to use.
#pod
#pod =for Pod::Coverage run
#pod
#pod =for Pod::Coverage BUILDARGS
#pod
#pod =cut

option type => (
    is      => 'ro',
    default => 'notice',
    format => 's',
    doc => '',
);

#pod =attr configfile
#pod
#pod Path to the optional configuration file. Defaults to C<$HOME/.software_license.conf>.
#pod
#pod =cut

option configfile => (
    is => 'ro',
    default => catfile(File::HomeDir->my_home, '.software_license.conf'),
    format => 's',
    doc => '',
    order => 100,
);

has _software_license => (
    is      => 'ro',
    isa     => sub { die "Not a Software::License" if !$_[0]->isa('Software::License') },
    lazy    => 1,
    builder => '_build__software_license',
    handles => {
        notice   => 'notice',
        text     => 'license',
        fulltext => 'fulltext',
        version  => 'version',
    },
);

sub _build__software_license {
    my ($self) = @_;
    my $class = "Software::License::${\$self->license}";

    return use_module($class)->new({
        holder => $self->holder,
        year   => $self->year,
    });
}

sub BUILDARGS {
    my $class = shift;

    my $args = { @_ };
    my $configfile = $args->{configfile} || catfile(File::HomeDir->my_home, '.software_license.conf');

    # Handling license as a trailing non-option argument
    if (!exists $args->{license}
            && scalar @ARGV && $ARGV[-1] !~ m{^--.+=.+}
            && (!scalar (@_) || $ARGV[-1] ne $_[-1])
    ) {
        $args->{license} = $ARGV[-1];
    }

    if (-e $configfile) {
        my $conf = Config::Any->load_files({ files => [$configfile], use_ext => 1, flatten_to_hash => 1 })->{ $configfile };
        $args = { %{ $conf || {} }, %$args };
    }
    return $args;
}

sub run {
    my ($self) = @_;
    my $meth = $self->type;
    print $self->_software_license->$meth;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Software::License - Command-line interface to Software::License

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    software-license --holder 'J. Random Hacker' --license Perl_5 --type notice

=head1 DESCRIPTION

This module provides a command-line interface to Software::License. It can be
used to easily produce license notices to be included in other documents.

All the attributes documented below are available as command-line options
through L<MooX::Options> and can also be configured in
F<$HOME/.software_license.conf> through L<Config::Any>.

=head1 ATTRIBUTES

=head2 holder

Name of the license holder.

=head2 year

Year to be used in the copyright notice.

=head2 license

Name of the license to use. Must be the name of a module available under the
Software::License:: namespace. Defaults to Perl_5.

=head2 type

The type of license notice you'd like to generate. Available values are:

B<* notice>

This method returns a snippet of text, usually a few lines, indicating the
copyright holder and year of copyright, as well as an indication of the license
under which the software is distributed.

B<* license>

This method returns the full text of the license.

=head2 configfile

Path to the optional configuration file. Defaults to C<$HOME/.software_license.conf>.

=for :stopwords fulltext

B<* fulltext>

This method returns the complete text of the license, preceded by the copyright
notice.

B<* version>

=for :stopwords versioned

This method returns the version of the license.  If the license is not
versioned, this returns nothing.

B<* meta_yml_name>

This method returns the string that should be used for this license in the CPAN
META.yml file, or nothing if there is no known string to use.

=for Pod::Coverage run

=for Pod::Coverage BUILDARGS

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Software-License>
(or L<bug-App-Software-License@rt.cpan.org|mailto:bug-App-Software-License@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/cpan-workers.html>.

There is also an irc channel available for users of this distribution, at
L<C<#toolchain> on C<irc.perl.org>|irc://irc.perl.org/#toolchain>.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Randy Stauner Erik Carlsson

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Erik Carlsson <info@code301.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
