package Acme::Schlong;
BEGIN {
  $Acme::Schlong::AUTHORITY = 'cpan:DBR';
}
{
  $Acme::Schlong::VERSION = '0.001';
}

#  PODNAME: Acme::Schlong
# ABSTRACT: Fun with Acme::Schlong!

use MooseX::Declare;
use true;

class Acme::Schlong with MooseX::Getopt::Strict {
    use 5.010;
    use feature 'switch';

    # Moose behavior
    use MooseX::StrictConstructor;
    use MooseX::AlwaysCoerce;
    use MooseX::Types::Moose -all;

    # infrastructure
    use MooseX::Attribute::ENV;
    use MooseX::Types::Path::Class 'Dir';
    use Path::Class 'dir', 'file';
    use Config::Any;

    use MooseX::Types::Perl 'StrictVersionStr';

    # information gathering helpers
    use App::OS::Detect::MachineCores;
    use version;
    use Carp;

    use File::Util;

    use MetaCPAN::API;

    # Post-Construction phase.
    method BUILD {
        use Acme::Emoticarp;
        o_O "Your system is Windows. I won't even bother calculating your schlong-size, sorry!" unless! ($^O ~~ /Win/ ... /Win/) # Just for fun (again)
    }

    sub true  { 1 }
    sub false { 0 }

    # The all mighty, all elementary information!
    has size => (
        is      => 'rw',
        isa     => Int,
        traits  => ['Number'],
        handles => {
            set_size => 'set',
            add_size => 'add',
            sub_size => 'sub',
            mul_size => 'mul',
            div_size => 'div',
            mod_size => 'mod',
            abs_size => 'abs',
        },
        required      => 1,
        lazy_build    => 1,
        documentation => q{The all might, all elementary information!},
    );

    has perl_specific   => ( is => 'ro', isa => Bool, traits => ['Getopt'], cmd_aliases => ['P'], default => 0 );

    has username        => ( is => 'ro', isa => Str,  traits => ['ENV'], env_key => 'user' );
    has home_directory  => ( is => 'ro', isa => Dir,  traits => ['ENV'], env_key => 'home' );
    has term            => ( is => 'ro', isa => Str,  traits => ['ENV'] );

    has useraccounts    => ( is => 'ro', isa => Int,  lazy_build => 1, documentation => q{Check if system is like /home/b/bruder ... then you have to also supply the hidden "I'm the administrator switch"} );
    has username_length => ( is => 'ro', isa => Int,  lazy_build => 1, documentation => q{self explanatory} );
    has shell           => ( is => 'ro', isa => Str,  lazy_build => 1, documentation => q{self explanatory} );
    has harddrive_size  => ( is => 'ro', isa => Int,  lazy_build => 1, documentation => q{self explanatory} );
    has harddrive_used  => ( is => 'ro', isa => Int,  lazy_build => 1, documentation => q{self explanatory} );
    has uptime          => ( is => 'ro', isa => Any,  lazy_build => 1, documentation => q{self explanatory} );
    has users           => ( is => 'ro', isa => Any,  lazy_build => 1, documentation => q{The number of users logged in on the system} );
    has cores           => ( is => 'ro', isa => Any,  lazy_build => 1, documentation => q{The Number of cores of this machine} );
    has using_multiplex => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{using screen or tmux});
    has using_byobu     => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{using byobu as multiplexer frontend!} );
    has using_tmux      => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{using tmux as multiplexer} );
    has using_screen    => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{using screen as multiplexer} );

    has perl_version           => ( is => 'ro', isa => StrictVersionStr, lazy_build => 1, documentation => q{The executing Perl's version number});
    has perl_version_is_dev    => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{The executing Perl's version number});
    has directories_in_path    => ( is => 'ro', isa => Int,  lazy_build => 1, documentation => q{The number of directories set in $PATH} );
    has using_perlbrew         => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_cpanm            => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_cpanm_customized => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{Has the user set specific flags to cpanm?} );
    has using_bash             => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_zsh              => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_ksh              => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_tcsh             => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_csh              => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    has using_dzil             => ( is => 'ro', isa => Bool, lazy_build => 1, documentation => q{self explanatory} );
    
    has pause_name             => ( is => 'ro', isa => Maybe[Str], lazy_build => 1, documentation => q{self explanatory});
    has cpan_modules           => ( is => 'ro', isa => Num,        lazy_build => 1, documentation => q[self explanatory]);

    has perls_installed        => ( is => 'ro', isa => Int, lazy_build => 1, documentation => q{the number of perls installed through perlbrew} );

    has known_hosts => ( is => 'ro', isa => Int, lazy_build => 1, documentation => q{self explanatory});
    has f => ( is => 'ro', isa => 'File::Util', default => sub { File::Util->new } );

    # has followers_on_github =>
    
    # has number_of_rc_files  =>  ~/.*rc
    # has length of .vimrc
    # has length of .emacs
    # has number of files in ~/.emacs.d
    # has using .ssh/config
    # has rvm/rbenv installed
    # 

    # has number_of_modules      => ( is => 'ro', isa => Int,  lazy_build => 1, documentation => q{} );

    method _build_useraccounts           { scalar grep { !/Shared/ } grep { -d $_ } glob ( dir( $self->home_directory => '..') . '/*'); } #TODO Make safer for WIN
    method _build_username_length        { length $self->username }
    method _build_shell                  { $_ = $ENV{SHELL}; s/.*\/(.*?)$/$1/; $_ } # /r
    method _build_harddrive_size         { $_=`df -l | grep '\\/\$' | awk '{print \$2}'`; chomp; $_ } # -E 'use IPC::Run qw<run timeout>; my $out; my @cmd = (q<du>, q<-s>, q</>); run \@cmd, "", \undef, \$out, timeout( 100 ) echo `uptime|grep days|sed 's/.*up \([0-9]*\) day.*/\1\/10+/'; \or die qq<ls: $?>; say $out; join q<>, @$out'
    method _build_harddrive_used         { $_=`df -l | grep '\\/\$' | awk '{print \$3}'`; chomp; $_ } # -E 'use IPC::Run qw<run timeout>; my $out; my @cmd = (q<du>, q<-s>, q</>); run \@cmd, "", \undef, \$out, timeout( 100 ) echo `uptime|grep days|sed 's/.*up \([0-9]*\) day.*/\1\/10+/'; \or die qq<ls: $?>; say $out; join q<>, @$out'
    method _build_uptime                 { 100 }
    method _build_users                  {  5  }
    method _build_cores                  { App::OS::Detect::MachineCores->new->cores }
    method _build_using_multiplex        { $self->using_byobu or $self->using_tmux or $self->using_screen ? true : false }
    method _build_using_byobu            { exists $ENV{BYOBU_BACKEND} ? 1 : 0 }
    method _build_using_tmux             { $ENV{TERM} ~~ 'tmux'       ? 1 : 0 }
    method _build_using_screen           { $ENV{TERM} ~~ 'screen'     ? 1 : 0 }
    method _build_perl_version           { $_ = `$^X --version`; m/perl.*\((?<vstring>v\d\.\d+.\d+)\) built for.*/; $+{vstring} }
    # method _build_perl_version_is_dev    { version->new($self->perl_version)->version->[1] % 2 ? 1 : 0 } # is_alpha
    method _build_directories_in_path    { scalar split q<:> =>      $ENV{PATH}         }
    method _build_using_perlbrew         { (grep { /perlbrew/i  }    keys %ENV) ? 1 : 0 }
    method _build_using_cpanm            { (grep { /cpanm/i     }    keys %ENV) ? 1 : 0 }
    method _build_using_cpanm_customized { !! (grep { /cpanm_opt/i } keys %ENV) || 0    } # TIMTOWDI just for fun
    method _build_using_bash             { $self->shell ~~ 'bash' || 0 }
    method _build_using_zsh              { $self->shell ~~ 'zsh'  || 0 }
    method _build_using_ksh              { $self->shell ~~ 'ksh'  || 0 }
    method _build_using_tcsh             { $self->shell ~~ 'tcsh' || 0 }
    method _build_using_csh              { $self->shell ~~ 'csh'  || 0 }
    method _build_using_dzil             { (grep {/.dzil/} glob (dir($self->home_directory) . '/' . '.*')) ? 1 : 0 }

    method _build_pause_name {
        Config::Any->load_files( {
            files => [ file($self->home_directory, '.dzil', 'config.ini') ],
            flatten_to_hash => 1,
            use_ext => 1 }
        )->{file($self->home_directory, '.dzil', 'config.ini')}
         ->{'%PAUSE'}
         ->{'username'};
    }
    method _build_cpan_modules  { scalar MetaCPAN::API->new->release(search => {author => $self->pause_name, filter => "distribution", fields=>"name"})->{hits}->{hits} }
    method _build_perls_installed { $_ =()= $self->f->list_dir("$ENV{PERLBREW_ROOT}/perls", '--dirs-only', '--no-fsdots') if exists $ENV{PERLBREW_ROOT} }
    method _build_known_hosts { $_ = `wc -l ~/.ssh/known_hosts | awk '{print \$1}'`; chomp; $_ }
    method _build_size {

        $self->size(0);

        # useraccounts
        # username_length
        # shell
        # harddrive_size
        # uptime
        # users
        # cores
        # using_multiplex
        # using_byobu
        # using_tmux
        # using_screen
        #
        # perl_version
        # perl_version_is_dev
        # directories_in_path
        # using_perlbrew
        # using_cpanm
        # using_cpanm_customized
        # using_bash
        # using_zsh
        # using_ksh
        # using_tcsh
        # using_csh
        
        # say for glob (dir($self->home_directory) . '/' . '.*');

        $self->add_size(10)  if $self->using_zsh;
        $self->add_size(100) if $self->using_multiplex;

        $self->add_size( 100 * $self->cores );

        $self->sub_size( 10 * $self->username_length );

        $self->abs_size
    }

    method testdrive {
        say "Your Acme Schlong size is: ", $self->size;
        say "Your username is: ", $self->username;
        say "Your home directory is: ", $self->home_directory;
        say "The number of useraccounts is ", $self->useraccounts;
        say "Your TERM is ", $self->term;
        say "Your shell is ", $self->shell;
        say "You are using byobu ", $self->using_byobu;
        say "Your username length is ", $self->username_length;
        say "You harddrive_size is ", $self->harddrive_size;
        say "The number of cores is ", $self->cores;
        say "Your perl version is  ", $self->perl_version;
        # say "Your perl version is a dev_release: ", $self->perl_version_is_dev;
        say "You have this many dirs in PATH: ", $self->directories_in_path;
        say "You are using a multiplexer: ", $self->using_multiplex;
        say "You are using perlbrew: ", $self->using_perlbrew;
        say "You are using zsh: ", $self->using_zsh;
        say "You are using bash: ", $self->using_bash;
        say "You are using cpanm: ", $self->using_cpanm;
        say "You are using cpanm customized: ", $self->using_cpanm_customized;
        say "You are using Dist::Zilla: ", $self->using_dzil;
        say "You have this many perls installed ", $self->perls_installed;
        say "Your PAUSE name is ", $self->pause_name;
        say "Your number of known hosts is ", $self->known_hosts;
        # say "Your number of modules released to the cpan is ", $self->cpan_modules;
    }

}


__END__
=pod

=encoding utf-8

=head1 NAME

Acme::Schlong - Fun with Acme::Schlong!

=head1 VERSION

version 0.001

=head1 SYNOPSIS

I remember, years ago, to have found one arcane incantation on the shell to calcuate your schlong size on your Linux box.

I was both amazed and curious and immediately tried it on my system (which happened to be OSX and it didn't work...).

Next, I tried it on the university's computers. It was way too cool.

Then, years later, I have found Perl::Achievements. It's a fun module.

It's a nice go-ahead-and-contribute-module. I wrote Perl::Achievements::Achievement::SchwartzianTransform for the fun of it.

So here is Acme::Schlong. Go ahead, contribute!

BTW: The arcane incantation was:

     echo `uptime|grep days|sed 's/.*up \([0-9]*\) day.*/\1\/10+/'; cat /proc/cpuinfo|grep MHz|awk '{print $4"/30 +";}'; free|grep '^Mem' | awk '{print $3"/1024/3+"}'; df -P -k -x nfs | grep -v 1k | awk '{if ($1 ~ "/dev/(scsi|sd)"){ s+= $2} s+= $2;} END {print s/1024/50"/15+70";}'`|bc|sed 's/\(.$\)/.\1cm/'

=for Pod::Coverage false true

=head1 TODO

=over

=item *

Find good ways to calculate the following:

=back

   * number of users logged in on the system (one user with 9 shells is 1 user.)
   * harddisk size
   * memory used
   * swap used
   * harddisk free space
   * uptime in minutes
   * running time in minutes
   * average load

=over

=item *

Find good infrastructure so that contributors can:

=back

   * easily extend to new metrics
   * calculate the new schlong size
   * all roles/subclasses are used

=over

=item *

Build Task:: Distribution so that everybody can keep his own stuff?

=item *

Versioning so that you can say "By metric XYZ your schlong size is XYZ" ?

=item *

More robust OS-specific stuff.

=item *

Send report to website

=back

=cut

=head1 AUTHOR

Daniel B. <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Daniel B..

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

