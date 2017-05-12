package Constant::Generator;

require 5.006001;
use Carp;
use strict;
use warnings 'all';
no warnings 'uninitialized';

our $VERSION = '1.013';
our %GEN;

my ($idx, $fl_set_ldr, $c);

my $ldr = sub{
    my $mod = pop;
    $GEN{$mod} ? (
	($c->{$mod} = 0),
	return sub{$c->{$mod} ? (($_=''),(keys(%$c) > 1 ? delete($c->{$mod}) : undef %$c),return undef) : (($_=$GEN{$mod}),return ++$c->{$mod})}
    ) : (
	return undef
    );
};

sub gen{
    my ($pkg, $list, $h) = @_;

    @_ > 1 or (
	$h = $pkg,
	($pkg, $list) = @$h{qw/pkg list/}
    );

    $h and (ref $h eq 'HASH' or croak "wrong usage: $h isn't hash");

    $pkg || croak 'no package name';
    ref $list eq 'ARRAY' and @$list > 0 or croak 'no constant names';

    $h->{fl_exp_ok} and $h->{fl_exp}=1;
    my @cnst_decls = map { &{$h->{sub_dcrtr} || sub{"\U$h->{prfx}$_[0]"}}($_) } @$list;
    undef $list;

    my ($i, $t, $WW) = defined($h->{int0}) ? $h->{int0} : 1;
    my $qr = qr/Bareword/oi;
    my %dcl = map{$_ => do{
	    $t = &{$h->{sub} || sub{$_[0]}}($i++);
	    local $SIG{__WARN__}=sub{($WW=join '',@_)=~$qr && die "bareword\n";};
	    eval $t;
	    $@=~$qr ? "\"$t\"" : $t
	}
    } @cnst_decls;
    undef @cnst_decls;

    my $s =
	'package '.$pkg.';'
	.($h->{fl_exp} ?
		'require Exporter;our @ISA=qw/Exporter/;'
	    :
		''
	).(
	    $constant::VERSION < 1.03 ? (
		'use constant '.(join 'use constant ', map{"$_=>$dcl{$_};"} keys %dcl)
	    ) : (
		'use constant {'.(join ',', map{"$_=>$dcl{$_}"} keys %dcl).'};'
	    )
	).($h->{fl_exp} ?
		'our @EXPORT'.($h->{fl_exp_ok} ? '_OK' : '').'=qw/'.(join ' ', keys %dcl).'/;'
	    :
		''
	).($h->{fl_decl} ?
		'our %CONSTS=('.(join ',', map{"$_=>$dcl{$_}"} keys %dcl).');'
	    :
		''
	).($h->{fl_rev} ?
		'our %STSNOC=('.(join ',', map{"$dcl{$_}=>\"$_\""} keys %dcl).');'
	    :
		''
	).('1');
    undef %dcl;

    unless($h->{fl_no_load}){
	eval $s;
	$@ && die("Constant generation error: $@");
    }

    my $fn = $pkg; $fn=~s/::/\//og; $fn .= '.pm';
    if(!$h->{fl_no_load} and $h->{fl_no_ldr}){
	$h->{fl_no_inc_stub} or $INC{$fn} = ''
    }

    $GEN{$fn} = $s;
    $fl_set_ldr || $h->{fl_no_ldr} || (
	$fl_set_ldr++,
	$idx = unshift(@INC, $ldr),
    );

    if($h->{fl_exp2file}){
	defined($h->{root_dir}) or ($h->{root_dir} = '.');
	-d ($h->{root_dir}) || (
	    warn("WARNING: export directory $h->{root_dir} isn't usable; force working directory to .\n"),
	    ($h->{root_dir} = '.'),
	);

	open my $fh, "> $h->{root_dir}/${fn}" or die "Can't create file $h->{root_dir}/$fn, error: $!\n";
	print $fh $s;
	close $fh;
    }

    $h->{sub_post_src} && &{$h->{sub_post_src}}($s);

    undef $_ for ($WW, $t, $h, $qr);

    1;
}

*generate = \&gen;

1;

=pod

=head1 NAME

Constant::Generator - this module bring flexible (I hope) constant generator to You

=head1 VERSION

version 1.013

=head1 DESCRIPTION

This module has only one short `workhorse' that implement constant generation logic.
This workhorse do perl-source code generation and come to you with extra power via options (logic modificators).
Let me save Your time in constant generation :).

=head1 SYNOPSYS

    use Constant::Generator;

    # eval use constant {ERR_SUCCESS => 1, ERR_PERMS => 2} and put constant names to @EXPORT_OK
    Constant::Generator::gen('Sys::Errors', [qw/success perms/], {fl_exp_ok => 1, prfx => 'ERR_',});

    # eval use constant {EV_SYNC => 1, EV_TIMEOUT => 2} and put EV_* constant name to @EXPORT
    Constant::Generator::gen('Sys::Events', [qw/sync timeout/], {fl_exp => 1, prfx => 'EV_',});

    # generate source code and save pm-file in specified path
    # if You're not ready to read `on-line' source files, perltidy can help you; enjoy :)
    Constant::Generator::gen('Sys::Flags', [qw/HTTP_REDIRECT SERVICE_NOT_AVAIL/], {
	fl_exp      => 1,     # generate source with exportable constants
	prfx        => 'FL_', # all constants has FL_ prefix
	fl_decl     => 0,     # don't fill Sys::Flags::CONSTS hash defined `key-value' pairs
	fl_rev      => 1,     # set Sys::Flags::STSNOC (reversed for CONSTS) hash with `value-key' pairs
	fl_no_load  => 1,     # don't load code
	fl_no_ldr   => 1,     # don't set loader at @INC
	fl_exp2file => 1,     # export source code to pm-file
	root_dir    => '/mnt/remote/sshfs/hypnotoad_controller', # yep, I'm mojolicious fun..so what? :)
    });

=head1 USE CASE

I think that this module is good solution to generate application constants at bootstrap time using predefined
lists and rules. It provide easy way to synchronize constants over network for linked services.

=head1 INTERFACE

=head2 Functions

=over 4

=item gen

    gen($pkg_name, $list_array, $options_hash);

    This sub implement full logic. Support two call forms:
    1) full form: Constant::Generator::gen('Sys::Event', [qw/alert warn/], {fl_exp => 1});
    2) all-in-options: Constant::Generator::gen({fl_exp => 1, pkg => 'Sys::Event', list => [qw/alert warn/]});

=back

=head2 Options

=over 4

=item pkg

(`package') usable only in second call form; package name for constants

=item list

(`list') usable only in second call form; array of constant names

=item  fl_exp

(`flag EXPORT') make constants auto-exportable (fill @EXPORT, man Exporter); so use Sys::Event will export
constants

=item  fl_exp_ok

(`flag EXPORT_OK') make constants exportable, but no autoexport (fill @EXPORT_OK, man Exporter);
so use Sys::Event qw'ALERT' will export ALERT constant

=item  prfx

(`prefix') prepend constant names with static prefix

=item  sub_dcrtr

(`sub decorator') by default, generator uppercase all constant names, but you can set custom constant name
decorator to evaluate constant names at runtime; this options also override prfx set:

    # generate constants using `rot13-decorator` to define constant names
    Constant::Generator::gen('TestPkg16', [qw/const33 const34/], {
	fl_exp => 1,
	fl_decl => 1,
	fl_rev => 1,
	prfx => 'CONST_',
	sub_dcrtr => sub{ # `rot13-decorator'
	    my $a = $_[0]=~tr/a-zA-Z/n-za-mN-ZA-M/r;
	},
    });

=item  int0

by default is 1 - value for first constant; autoincrement for next constants;

=item  sub

(`substitute') set function to disable default constant evaluation (int0 option) that will
generate constant values, ex:

    # customized constant values
    Constant::Generator::gen('TestPkg5', [qw/const11 const12/], {
	fl_exp => 1,
	sub => sub{($_[0]<<2)}
    });


=item  fl_decl

(`flag declaration') is set, after definition all constants and values will be available at
%{__PACKAGE__::CONSTS} hash

=item  fl_rev

(`flag reverse declaration') same as above but reversed pair (values => keys) will be available at
%{__PACKAGE__::STSNOC} hash

=item  fl_no_load

(`flag no loading') don't load constants, i.e. generator don't call eval for generated source code

=item  fl_no_ldr

(`flag no loader') don't put loader sub into @INC

=item  fl_no_inc_stub

(`flag no %INC stub') this options usable only if fl_no_load isn't set and fl_no_ldr is set;
if flag is not set then generator set $INC{__PACKAGE__} to '' (this stub allow to load module
later even without loader in @INC). Set flag to disable it (use will throw an error).

    Constant::Generator::gen('TestPkg18', [qw/const37 const38/], {
	    fl_exp => 1,
	    fl_no_load => 0,
	    fl_no_ldr  => 1,
	    fl_no_inc_stub => 1, # default is 0
	});
    # here $INC{TestPkg18} is set to ''
    ...
    use TestPkg18;
    # here we have two exported constants: CONST37 and CONST38

=item  fl_exp2file

(`flag export to file') if flag is set than constant generator will export source to pm-file

=item  root_dir

(`root directory') directory for generated sources; '.' by default

=item  sub_post_src

(`sub post source') provide custom function to accept generated source code in first argument

    sub src_print{
	print $_[0];
    }

    Constant::Generator::gen('TestPkg23', [qw/const47 const48/], {
	...
	sub_post_src => \&src_print
    });

=back

=head1 AUTHOR

 Tvori Dobro

=head1 COPYRIGHT AND LICENSE

 This library is free software; you can redistribute it and/or modify
 it under the same terms as Perl itself.

=cut
