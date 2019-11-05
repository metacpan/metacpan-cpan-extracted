package main;

use strict;
use warnings;

use Test::More 0.88;

use Cwd qw{ cwd };

use lib qw{ inc/mock inc };
use Astro::App::Satpass2::Utils qw{ HASH_REF REGEXP_REF };
use My::Module::Test::App;	# for environment clean-up.

use File::HomeDir;	# Mocked

sub dump_tokens;
sub new;
sub set_positional (@);
sub tokenize (@);
sub tokenize_fail (@);

use Astro::App::Satpass2;
use Astro::App::Satpass2::Utils qw{ my_dist_config };

new;

tokenize 'foo', [ [ 'foo' ], {} ]
    or dump_tokens;

tokenize 'foo  bar', [ [ qw{ foo bar } ], {} ]
    or dump_tokens;

=begin comment

tokenize "foo\nbar", [ [ qw{ foo } ], {} ];

tokenize undef, [ [ qw{ bar } ] ], 'tokenize remainder of source';

tokenize "foo\\\nbar", [ [ 'foobar' ], {} ];

=end comment

=cut

tokenize q{foo'bar'}, [ [ qw{ foobar } ], {} ]
    or dump_tokens;

tokenize qq{foo'bar\nbaz'}, [ [ "foobar\nbaz" ], {} ]
    or dump_tokens;

=begin comment

# $'...' not understood by built-in tokenizer.

tokenize q{foo$'bar'}, [ [ 'foobar' ], {} ]
    or dump_tokens;

tokenize qq{foo\$'bar\nbaz'}, [ [ "foobar\nbaz" ], {} ]
    or dump_tokens;

=end comment

=cut

tokenize q{foo"bar"}, [ [ 'foobar' ], {} ]
    or dump_tokens;

tokenize qq{foo"bar\nbaz"}, [ [ "foobar\nbaz" ], {} ]
    or dump_tokens;

tokenize <<'EOD', [ [ "foobar\nbaz" ], {} ]
foo"bar
baz"
EOD
    or dump_tokens;

tokenize <<'EOD', [ [ "foo bar\nbaz\n" ], {} ]
<<END_OF_DATA
foo bar
baz
END_OF_DATA
EOD
    or dump_tokens;

tokenize q{foo"bar\\nbaz"}, [ [ "foobar\nbaz" ], {} ]
    or dump_tokens;

tokenize q{foo#bar}, [ [ 'foo#bar' ], {} ]
    or dump_tokens;

tokenize q{foo # bar}, [ [ 'foo' ], {} ]
    or dump_tokens;

tokenize q{# foo bar}, [ [], {} ]
    or dump_tokens;

tokenize q<foo{bar}>, [ [ 'foo{bar}' ], {} ]
    or dump_tokens;

tokenize q<foo{bar>, [ [ 'foo{bar' ], {} ]
    or dump_tokens;

tokenize q<foobar}>, [ [ 'foobar}' ], {} ]
    or dump_tokens;

=begin comment

# brace expansion not supported.

tokenize q<foo{bar,baz}>, [ [ qw{ foobar foobaz ], {} ]
    or dump_tokens;

tokenize q<foo{bar,{baz,burfle}}>,
    [ [ qw{ foobar foobaz fooburfle } ], {} ]
    or dump_tokens;

tokenize q<foo{bar,x{baz,burfle}}>,
    [ [ qw{ foobar fooxbaz fooxburfle ], {} ]
    or dump_tokens;

=end comment

=cut

tokenize q{x~+}, [ [ 'x~+' ], {} ]
    or dump_tokens;

tokenize q{~+}, [ [ cwd() ], {} ]
    or dump_tokens;

tokenize q{~+/foo}, [ [ cwd() . '/foo' ], {} ]
    or dump_tokens;

tokenize q{x~}, [ [ 'x~' ], {} ]
    or dump_tokens;

{


    my $home = '/home/menuhin';
    local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_HOME = $home;

    tokenize q{~}, [ [ $home ], {} ]
	or dump_tokens;

    tokenize q{~/foo}, [ [ "$home/foo" ], {} ]
	or dump_tokens;

}

{
    my $home = {
	menuhin	=> '/home/menuhin',
    };
    local $File::HomeDir::MOCK_FILE_HOMEDIR_USERS_HOME = $home;

    tokenize q{~menuhin}, [ [ $home->{menuhin} ], {} ]
	or dump_tokens;

    tokenize q{~menuhin/foo}, [ [ "$home->{menuhin}/foo" ], {} ]
	or dump_tokens;

    tokenize { fail => 1 }, q{~pearlman},
	qr{ \A Unable \s to \s find \s home \s for \s pearlman }smx,
	'Tokenize ~pearlman should fail';

    tokenize { fail => 1 }, q{~pearlman/foo},
	qr{ \A Unable \s to \s find \s home \s for \s pearlman }smx,
	'Tokenize ~pearlman/foo should fail';

}

{

    my $cfg = '/home/menuhin/.local/perl/Astro-App-Satpass2';
    local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_DIST_CONFIG = $cfg;

    tokenize q{~~}, [ [ $cfg ], {} ]
	or dump_tokens;

    tokenize q{~~/foo}, [ [ "$cfg/foo" ], {} ]
	or dump_tokens;

}

{

    local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_DIST_CONFIG = undef;

    tokenize { fail => 1 }, q{~~},
	qr{ \A Unable \s to \s find \s ~~ }smx,
	'Tokenize ~~ without dist dir should fail';

    tokenize { fail => 1 }, q{~~/foo},
	qr{ \A Unable \s to \s find \s ~~ }smx,
	'Tokenize ~~/foo without dist dir should fail';
}

local $ENV{foo} = 'bar';
local $ENV{bar} = 'baz';
local @ENV{ qw{ fooz yehudi } };
delete $ENV{fooz};
delete $ENV{yehudi};

tokenize q{$foo}, [ [ 'bar' ], {} ]
    or dump_tokens;

tokenize q{"$foo"}, [ [ 'bar' ], {} ]
    or dump_tokens;

tokenize q{'$foo'}, [ [ '$foo' ], {} ]
    or dump_tokens;

tokenize <<'EOD', [ [ "bar\n" ], {} ]
<<END_OF_DOCUMENT
$foo
END_OF_DOCUMENT
EOD
    or dump_tokens;

tokenize <<'EOD', [ [ "bar\n" ], {} ]
<<"END_OF_DOCUMENT"
$foo
END_OF_DOCUMENT
EOD
    or dump_tokens;

tokenize <<'EOD', [ [ "\$foo\n" ], {} ]
<<'END_OF_DOCUMENT'
$foo
END_OF_DOCUMENT
EOD
    or dump_tokens;

=begin comment

# $'...' not supported

tokenize q{$'$foo'}, [ [ '$foo' ], {} ]
    or dump_tokens;

=end comment

=cut

tokenize q<${foo}bar>, [ [ 'barbar' ], {} ]
    or dump_tokens;

=begin comment

# ${#..} not supported except on $@ and $*

tokenize q<${#foo}>, [ [ '3' ], {} ]
    or dump_tokens;

=end comment

=cut

tokenize q<${!foo}>, [ [ 'baz' ], {} ]
    or dump_tokens;

tokenize q<$burfle>, [ [], {} ]
    or dump_tokens;

set_positional qw{ one two three };

=begin comment

# Arrays not supported

tokenize q<${plural[0]}>, [ [ 'zero' ], {} ]
    or dump_tokens;

tokenize q<${plural[1]}>, [ [ 'one' ], {} ]
    or dump_tokens;

tokenize q<${plural[2]}>, [ [ 'two' ], {} ]
    or dump_tokens;

tokenize q<${#plural}>, [ [ '4' ], {} ]
    or dump_tokens;

tokenize q<${#@}>, [ [ '3' ], {} ]
    or dump_tokens;

tokenize q<${#plural[*]}>, [
    { type => 'word', content => '3' } ]
    or dump_tokens;

tokenize q<${#plural[0]}>, [
    { type => 'word', content => '4' } ]
    or dump_tokens;

tokenize q<${#plural[1]}>, [
    { type => 'word', content => '3' } ]
    or dump_tokens;

tokenize q<${#plural[2]}>, [
    { type => 'word', content => '3' } ]
    or dump_tokens;

tokenize q<${#plural[3]}>, [
    { type => 'word', content => '0' } ]
    or dump_tokens;

=end comment

=cut

tokenize q<$#>, [ [ '3' ], {} ]
    or dump_tokens;

tokenize q<$*>, [ [ qw{ one two three } ], {} ]
    or dump_tokens;

tokenize q<$@>, [ [ qw{ one two three } ], {} ]
    or dump_tokens;

tokenize q<'$*'>, [ [ '$*' ], {} ]
    or dump_tokens;

tokenize q<'$@'>, [ [ '$@' ], {} ]
    or dump_tokens;

tokenize q<"$*">, [ [ 'one two three' ], {} ]
    or dump_tokens;

tokenize q<"$@">, [ [ qw{ one two three } ], {} ]
    or dump_tokens;

tokenize q<"xx$@yy">, [ [ qw{ xxone two threeyy } ], {} ]
    or dump_tokens;

set_positional 'o ne', 'two';

tokenize q<xx$@yy>, [ [ qw{ xxo ne twoyy } ], {} ]
    or dump_tokens;

tokenize q<"xx$@yy">, [ [ 'xxo ne', 'twoyy' ], {} ]
    or dump_tokens;

tokenize q<xx$*yy>, [ [ qw{ xxo ne twoyy } ], {} ]
    or dump_tokens;

tokenize q<"xx$*yy">, [ [ 'xxo ne twoyy' ], {} ]
    or dump_tokens;

tokenize q<${foo:-flurfle}>, [ [ 'bar' ], {} ]
    or dump_tokens;

tokenize q<${fooz:-flurfle}>, [ [ 'flurfle' ], {} ]
    or dump_tokens;

tokenize q<${fooz}>, [ [], {} ]
    or dump_tokens;

tokenize q<${fooz:=flurfle}>, [ [ 'flurfle' ], {} ]
    or dump_tokens;

tokenize q<$fooz>, [ [ 'flurfle' ], {} ]
    or dump_tokens;

tokenize q<${foo:?not foolish}>, [ [ 'bar' ], {} ]
    or dump_tokens;

tokenize_fail q<${yehudi:?not foolish}>, qr{\Qnot foolish}smx;

tokenize q<${foo:+foolish}>, [ [ 'foolish' ], {} ]
    or dump_tokens;

tokenize q<${yehudi:+foolish}>, [ [], {} ]
    or dump_tokens;

tokenize q<${foo:1}>, [ [ 'ar' ], {} ]
    or dump_tokens;

tokenize q<${foo:1:1}>, [ [ 'a' ], {} ]
    or dump_tokens;

tokenize q<${foo: -1}>, [ [ 'r' ], {} ]
    or dump_tokens;

=begin comment

# Arrays not supported except $@

tokenize q<${plural[*]:1}>, [
    { type => 'word', content => 'one' },
    { type => 'white_space', content => ' ' },
    { type => 'word', content => 'two' } ]
    or dump_tokens;

tokenize q<${plural[*]:1:1}>, [
    { type => 'word', content => 'one' } ]
    or dump_tokens;

tokenize q<${plural[*]: -1}>, [
    { type => 'word', content => 'two' } ]
    or dump_tokens;

=end comment

=cut

set_positional qw{ fee };

tokenize '${@:1:2}', [ [], {} ]
    or dump_tokens;

set_positional qw{ fee fie };

tokenize '${@:1:2}', [ [ 'fie' ], {} ]
    or dump_tokens;

set_positional qw{ fee fie foe };

tokenize '${@:1:2}', [ [ qw{ fie foe } ], {} ]
    or dump_tokens;

set_positional qw{ fee fie foe fum };

tokenize '${@:1:2}', [ [ qw{ fie foe } ], {} ]
    or dump_tokens;

tokenize '$0', [ [ $0 ], {} ]
    or dump_tokens;

tokenize '$_', [ [ $^X ], {} ]
    or dump_tokens;

tokenize '$$', [ [ $$ ], {} ]
    or dump_tokens;

tokenize '"\u\LFEE FIE FOE\E FOO"', [ [ 'Fee fie foe FOO' ], {} ]
    or dump_tokens;

tokenize '"Fee \U$2\E foe \u$foo"', [ [ 'Fee FIE foe Bar' ], {} ]
    or dump_tokens;

done_testing;

{

    my $dumper;
    BEGIN {
	$dumper = eval {
	    require YAML;
	    YAML->can( 'Dump' );
	} || eval {
	    require Data::Dumper;
	    Data::Dumper->can( 'Dumper' );
	};
    }

    my @got;
    my @positional;
    my $tt;

    sub _format_method_args {
	my @args = @_;
	my @rslt;
	my $name = shift( @args ) . '(';
	while ( @args ) {
	    my ( $name, $value ) = splice @args, 0, 2;
	    if ( defined $value ) {
		$value =~ m/ \A \d+ \z /smx
		    or $value = "'$value'";
	    } else {
		$value = 'undef';
	    }
	    push @rslt, "$name => $value";
	}
	return $name . join( ', ', @rslt ) . ')';
    }

    sub dump_tokens {
	$dumper and diag( $dumper->( \@got ) );
	return;
    }

    sub new {	## no critic (RequireArgUnpacking)
	my @args = @_;
	@got = ();
	my $name = _format_method_args( new => @args );
	if ( $tt = eval {
		Astro::App::Satpass2->new( @args );
	    } ) {
	    @_ = ( $name );
	    goto &pass;
	} else {
	    $name.= " failed: $@";
	    chomp $name;
	    @_ = ( $name );
	    goto &fail;
	}
    }

    sub set_positional (@) {
	@positional = @_;
	return;
    }

    my ( %escape_char, $escape_re );
    BEGIN {
	%escape_char = (
	    '\\'	=> '\\\\',
	    "\n"	=> '\\n',
	    "\t"	=> '\\t',
	);
	$escape_re = join '', sort values %escape_char;
	$escape_re = qr{ [$escape_re] }smx;
    }

    sub tokenize (@) {	## no critic (RequireArgUnpacking)
	my @args = @_;
	my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
	my ( $source, $tokens, $name ) = @args;
	if ( $source =~ m/ \n /sxm ) {
	    my @src = split qr{ (?<= \n ) }sxm, $source;
	    $source = shift @src;
	    $opt->{in} = sub { return shift @src };
	}
	@got = ();
	if ( ! defined $name ) {
	    ( $name = $source ) =~ s/ ( $escape_re ) / $escape_char{$1}
	    /smxeg;
	    $name = 'tokenize ' . $name;
	}
	SKIP: {
	    $tt or skip( 'Failed to instantiate application', 1 );
	    if ( eval {
		    @got = $tt->_tokenize( $opt, $source, \@positional );
		    1;
		} ) {
		if ( $opt->{fail} ) {
		    @_ = ( "$name unexpectedly succeeded" );
		    goto &fail;
		} else {
		    @_ = ( \@got, $tokens, $name );
		    goto &is_deeply;
		}
	    } else {
		my $err = $@;
		if ( $opt->{fail} ) {
		    if ( $err =~ m/$tokens/ ) {
			@_ = ( $name );
			goto &pass;
		    } else {
			$name .= ": $err";
			chomp $name;
			@_ = ( $name );
			goto &fail;
		    }
		} else {
		    $name .= ": $err";
		    chomp $name;
		    @_ = ( $name );
		    goto &fail;
		}
	    }
	}
	return;
    }

    sub tokenize_fail (@) {	## no critic (RequireArgUnpacking)
	my @args = @_;
	my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
	my ( $source, $message, $name ) = @args;
	@got = ();
	if ( ! defined $name ) {
	    ( $name = $source ) =~ s/ ( $escape_re ) / $escape_char{$1}
	    /smxeg;
	    $name = 'tokenize ' . $name . ' fails';
	}
	SKIP: {
	    $tt or skip( 'Failed to instantiate application', 1 );
	    if ( eval {
		    @got = $tt->_tokenize( $opt, $source, \@positional );
		    1;
		} ) {
		@_ = ( "$name succeeded unexpectedly" );
		goto &fail;
	    } else {
		REGEXP_REF eq ref $message
		    or $message = qr{ $message }smx;
		@_ = ( $@, $message, $name );
		goto &like;
	    }
	}
	return;
    }

}


1;

# ex: set textwidth=72 :
