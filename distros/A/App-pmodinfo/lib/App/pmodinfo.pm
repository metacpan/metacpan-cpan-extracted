
package App::pmodinfo;

use strict;
use warnings;
use Getopt::Long ();
use File::stat;
use DateTime;
use Config;
use Parse::CPAN::Meta;
use LWP::Simple;
use ExtUtils::Installed;
use File::Which qw(which);

our $VERSION = '0.10'; # VERSION

sub new {
    my $class = shift;

    bless {
        author => 0,
        full   => 0,
        hash   => 0,
        @_
    }, $class;
}

sub parse_options {
    my $self = shift;

    $self->{argv} = \@ARGV;

    Getopt::Long::Configure("bundling");
    Getopt::Long::GetOptions(
        'v|version!'       => sub { $self->show_version },
        'f|full!'          => sub { $self->{full} = 1 },
        'h|hash!'          => sub { $self->{hash} = 1 },
        'c|cpan!'          => sub { $self->{cpan} = 1 },
        'l|local-modules!' => sub { $self->show_installed_modules },
        'u|check-updates'  => sub { $self->check_installed_modules_for_update },
    );

}

sub show_version {
    my $self = shift;
    no strict;    # Dist::Zilla, VERSION.
    print "pmodinfo version $VERSION\n";
    exit 0;
}

sub show_help {
    my $self = shift;

    if ( $_[0] ) {
        die <<USAGE;
Usage: pmodinfo Module [...]

Try `pmodinfo --help` for more options.
USAGE
    }

    print <<HELP;
Usage: pmodinfo [options] [Module] [...]

    -v --version            Display software version
    -f --full               Turns on the most output
    -h --hash               Show module and version in a hash.
    -l,--local-modules      Display all local modules
    -u,--check-updates      Check updates, compare your local version to cpan.
    -c,--cpan               Show the last version of module in cpan.

HELP

    exit 0;
}

sub print_block {
    my $self = shift;
    my ( $description, $data, @check ) = @_;
    map { print "  $description: $data\n" if $_ } @check;
}

sub format_date {
    my ( $self, $epoch ) = @_;
    return '' unless $epoch;
    my $dt = DateTime->from_epoch( epoch => $epoch );
    return join( ' ', $dt->ymd, $dt->hms );
}

sub run {
    my $self = shift;

    $self->show_help unless @{ $self->{argv} };

    $self->ns_argv;

    print "{\n" if $self->{hash};

    for my $module ( @{ $self->{argv} } ) {
        $self->{hash}
            ? $self->show_modules_hash($module)
            : $self->show_modules($module);
    }

    print "};\n" if $self->{hash};
}

sub show_modules_hash {
    my ( $self, $module ) = @_;
    my ( $install, $meta ) = $self->check_module( $module, 0 );
    return unless $meta and $meta->version;
    my $version = $meta->version;
    print "\t'$module' => $version,\n" if $install;
}

sub cpanpage {
    my ( $self, $module ) = @_;
    $module =~ s/::/-/g;
    return "http://search.cpan.org/dist/$module";
}

sub update_modules {
    my ( $self, @modules ) = @_;
    my $cpan_util;
    $cpan_util = which('cpanm') or which('cpan') or exit -1;
    system( $cpan_util, @modules );
    exit 0;
}

sub ns_argv {
    my $self = shift;
    my @nargv;
    my @installed = $self->installed_modules;

    foreach my $arg ( @{ $self->{argv} } ) {
        if ($arg =~ /::$/) {
            my $mod = $arg;
            $mod =~ s/::$//;
            push( @nargv, $mod);
        } else {
            push( @nargv, $arg );
        }
    }

    foreach my $mod (@installed) {
        foreach my $arg ( @{ $self->{argv} } ) {
            next unless $arg =~ /::$/;
            next unless $mod =~ /^$arg/;
            push( @nargv, $mod );
        }
    }

    $self->{argv} = \@nargv;
}

sub check_installed_modules_for_update {
    my $self = shift;
    my @need_update;

    $self->ns_argv;

    foreach my $module ( scalar( @{ $self->{argv} } ) ? @{ $self->{argv} } : $self->installed_modules ) {
        my ( $install, $meta ) = $self->check_module( $module, 0 );
        next unless $install and defined($meta);

        my $local_version = $meta->version;
        my $cpan_version  = $self->get_last_version_from_cpan($module);
        next unless $cpan_version and $local_version;
        next if $cpan_version eq $local_version;

        print "$module local version: $local_version, last version in cpan: $cpan_version\n";

        push( @need_update, $module );
    }

    if ( scalar(@need_update) ) {
        my $ans = lc $self->prompt( "Do you need to update this modules now ? (y/n)", "n" );
        $self->update_modules(@need_update) if $ans eq 'y';
    }
    else {
        print "already up to date.";
    }

    exit 0;
}

sub prompt {
    my ( $self, $mess, $def ) = @_;

    my $isa_tty = -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";

    if ( ( !$isa_tty && eof STDIN ) ) {
        return $def;
    }

    local $| = 1;
    local $\;
    my $ans;
    eval {
        local $SIG{ALRM} = sub {
            undef $ans;
            die "alarm\n";
        };
        print STDOUT "$mess $dispdef";
        $ans = <STDIN>;
        alarm 0;
    };
    if ( defined $ans ) {
        chomp $ans;
    }
    else {    # user hit ctrl-D or alarm timeout
        print STDOUT "\n";
    }

    return ( !defined $ans || $ans eq '' ) ? $def : $ans;
}

sub show_installed_modules {
    my $self = shift;

    $self->ns_argv;

    foreach my $module ( scalar( @{ $self->{argv} } ) ? @{ $self->{argv} } : $self->installed_modules ) {
        my ( $install, $meta, $deprecated ) = $self->check_module( $module, 0 );
        next unless $install and $meta->version;
        print "$module version is " . $meta->version;
        print "(deprecated)" if defined($deprecated);
        print ".\n";
    }
    exit 0;
}

sub installed_modules {
    my $self    = shift;
    my $inst    = ExtUtils::Installed->new();
    my @modules = $inst->modules();
    return @modules;
}

sub show_modules {
    my ( $self, $module ) = @_;
    my ( $install, $meta, $deprecated ) = $self->check_module( $module, 0 );

    print "$module not found.\n" and return unless $install and $meta->version;

    print "$module version is " . $meta->version;
    print "(deprecated)" if defined($deprecated);
    print ".\n";

    my $stat  = stat $meta->filename;
    my $ctime = $self->format_date( $stat->[10] );
    $self->print_block( 'cpan page  ', $self->cpanpage($module), $self->{full} );
    $self->print_block( 'filename   ', $meta->filename,          $self->{full} );
    $self->print_block( '  ctime    ', $ctime,                   $self->{full} );
    $self->print_block(
        'POD content',
        (   $meta->contains_pod
            ? 'yes'
            : 'no'
        ),
        $self->{full}
    );

    if ( $self->{full} or $self->{cpan} ) {
        my $cpan_version = $self->get_last_version_from_cpan($module);
        $self->print_block( 'Last cpan version', $cpan_version, 1 );
    }
}

sub parse_meta_string {
    my ( $self, $yaml ) = @_;
    return eval { ( Parse::CPAN::Meta::Load($yaml) )[0] } || undef;
}

sub get_last_version_from_cpan {
    my ( $self, $module ) = @_;
    $module =~ s/::/-/g;
    my $meta_yml = get("http://search.cpan.org/meta/$module/META.yml");
    my $meta     = $self->parse_meta_string($meta_yml);
    return $meta->{version};
}

# check_module from cpanminus.
sub check_module {
    my ( $self, $mod, $want_ver ) = @_;

    my $meta = do {
        no strict 'refs';
        local ${"$mod\::VERSION"};
        require Module::Metadata;
        Module::Metadata->new_from_module( $mod, inc => $self->{search_inc} );
        }
        or return 0, undef;

    my $version = $meta->version;

    # When -L is in use, the version loaded from 'perl' library path
    # might be newer than the version that is shipped with the current perl
    if ( $self->{self_contained} && $self->loaded_from_perl_lib($meta) ) {
        my $core_version = eval {
            require Module::CoreList;
            $Module::CoreList::version{ $] + 0 }{$mod};
        };

        # HACK: Module::Build 0.3622 or later has non-core module
        # dependencies such as Perl::OSType and CPAN::Meta, and causes
        # issues when a newer version is loaded from 'perl' while deps
        # are loaded from the 'site' library path. Just assume it's
        # not in the core, and install to the new local library path.
        # Core version 0.38 means >= perl 5.14 and all deps are satisfied
        if ( $mod eq 'Module::Build' ) {
            if ($version < 0.36 or    # too old anyway
                ( $core_version != $version and $core_version < 0.38 )
                )
            {
                return 0, undef;
            }
        }

        $version = $core_version if %Module::CoreList::version;
    }

    $self->{local_versions}{$mod} = $version;

    if ( $self->is_deprecated($meta) ) {
        return 0, $meta, 1;
    }
    elsif ( !$want_ver or $version >= version->new($want_ver) ) {
        return 1, $meta;
    }
    else {
        return 0, $version;
    }
}

sub is_deprecated {
    my ( $self, $meta ) = @_;

    my $deprecated = eval {
        require Module::CoreList;
        Module::CoreList::is_deprecated( $meta->{module} );
    };

    return unless $deprecated;
    return $self->loaded_from_perl_lib($meta);
}

sub loaded_from_perl_lib {
    my ( $self, $meta ) = @_;

    require Config;
    for my $dir (qw(archlibexp privlibexp)) {
        my $confdir = $Config{$dir};
        if ( $confdir eq substr( $meta->filename, 0, length($confdir) ) ) {
            return 1;
        }
    }

    return;
}

1;


=pod

=head1 NAME

App::pmodinfo - Perl module info command line.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

pmodinfo extracts information from the perl modules given the command
line, usign L<Module::Metadata>, L<Module::CoreList>, L<Module::Build>,
L<Parse::CPAN::Meta> and L<ExtUtils::Installed>.

I don't want to use more "perl -MModule\ 999".

See L<pmodinfo> for more information.

=head1 DEVELOPMENT

App::modinfo is a open source project for everyone to participate. The code
repository is located on github. Feel free to send a bug report or a pull
request.

L<http://www.github.com/maluco/App-pmodinfo>

=head1 SEE ALSO

L<Module::Metadata>, L<Module::CoreList>, L<Module::Build>,
L<Parse::CPAN::Meta>, L<ExtUtils::Installed>.

=head1 ACKNOWLEDGE

L<cpanminus>, for the check_module, prompt function and inspiration. :-)

=head1 AUTHOR

Thiago Rondon <thiago@nsms.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

# ABSTRACT: Perl module info command line.


