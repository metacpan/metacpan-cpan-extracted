use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::FileWriter;
use base 'Class::Data::Inheritable', 'Class::Accessor';
use Template;
use File::Slurp;

__PACKAGE__->mk_classdata('Files', {});
__PACKAGE__->mk_accessors(qw(root_dir));

sub new {
	my $self = shift()->SUPER::new(@_);
	$self->{root_dir} ||= '.';
	return $self;
}

sub _normalize_options {
	my ($self, $orig_opts, $new_opts) = @_;
	my %res = map { $_, 
		exists($new_opts->{$_}) ? $new_opts->{$_} : $orig_opts->{$_}
	} (keys(%$orig_opts), keys(%$new_opts));
	if (my $c = $res{class}) {
		$res{path} = "lib/$c.pm";
		$res{contents} = <<ENDS;
use strict;
use warnings FATAL => 'all';

package $c;
$res{contents}
1;
ENDS
	}
	$res{path} =~ s/::/\//g if $res{path};
	return \%res;
}

sub _write_file {
	my ($self, $n, $vars, $new_opts) = @_;
	my $opts = $self->_normalize_options($self->Files->{$n}, $new_opts);
	my $p = $opts->{path};
	$p = $p->($opts) if ref($p);
	my $f = $self->root_dir . "/$p";
	die "Cowardly refusing to overwrite $f"
		if (-f $f && !$opts->{overwrite});
	$vars = $self->_normalize_options($opts->{vars}, $vars)
			if $opts->{vars};
	my $t = Template->new({ OUTPUT_PATH => $self->root_dir,
				%{ $opts->{tmpl_options} || {} } })
			or die "No template";
	$t->process(\$opts->{contents}, $vars, $p)
		or die "No result for $n: " . $t->error;

	write_file($self->root_dir . "/MANIFEST", { append => 1 }
			, "\n$p\n") if $opts->{manifest};
}

sub _mangle_name_to_path {
	my ($class, $n) = @_;
	my $p = $$n;
	$$n = lc($p);
	$$n =~ s/[\.\/]/_/g;
	return $p;
}

sub _prepare_contents {
	my ($class, $opts, $contents) = @_;
	return $contents unless ref($contents);
	my $uses = $opts->{uses} or return $contents->[0];
	my $u_opts = $class->Files->{$uses} or die "Unable to find $uses";
	my $t = Template->new or die "No template";
	my $u_cont = $class->_prepare_contents($u_opts, $u_opts->{contents});
	my $res;
	my %h = @$contents;
	$h{$_} = "[% $_ %]" for @{ $opts->{propagate} || [] };
	$t->process(\$u_cont, \%h, \$res)
		or die "No result for $uses: " . $t->error;
	return $res;
}

sub add_file {
	my ($class, $opts, @contents) = @_;
	my $n = $opts->{name} or die "No name found";
	$opts->{contents} ||= $class->_prepare_contents($opts, \@contents);
	my $new_path = $class->_mangle_name_to_path(\$n);
	$opts->{path} ||= $new_path;
	$class->Files->{$n} = $opts;
	no strict 'refs';
	*{ "$class\::write_$n" } = sub {
		shift()->_write_file($n, @_);
	};
}

1;
