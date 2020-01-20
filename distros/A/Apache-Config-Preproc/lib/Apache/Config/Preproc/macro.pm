package Apache::Config::Preproc::macro;
use parent 'Apache::Config::Preproc::Expand';
use strict;
use warnings;
use Text::ParseWords;
use Carp;

our $VERSION = '1.03';

sub new {
    my $class = shift;
    my $conf = shift;
    my $self = bless $class->SUPER::new($conf), $class;
    $self->{keep} = {};
    croak "bad number of arguments: @_" if @_ % 2;
    local %_ = @_;
    my $v;
    if ($v = delete $_{keep}) {
	if (ref($v)) {
	    croak "keep argument must be a scalar or listref"
		unless ref($v) eq 'ARRAY';
	} else {
	    $v = [$v];
	}
	@{$self->{keep}}{@$v} = @$v;
    }
    croak "unrecognized arguments" if keys(%_);
    return $self;
}

sub macro {
    my ($self, $name) = @_;
    return $self->{macro}{$name};
}

sub install_macro {
    my ($self, $defn) = @_;
    return 0 if $self->{keep}{$defn->name};
    $self->{macro}{$defn->name} = $defn;
    return 1;
}

sub expand {
    my ($self, $d, $repl) = @_;
    if ($d->type eq 'section' && lc($d->name) eq 'macro') {
	return $self->install_macro(Apache::Config::Preproc::macro::defn->new($d));
    } 
    if ($d->type eq 'directive' && lc($d->name) eq 'use') {
	my ($name,@args) = parse_line(qr/\s+/, 0, $d->value);
	if (my $defn = $self->macro($name)) {
	    push @$repl, $defn->expand(@args);
	    return 1;
	}
    }
    return 0;
}

package Apache::Config::Preproc::macro::defn;
use strict;
use warnings;
use Text::ParseWords;

sub new {
    my $class = shift;
    my $d = shift;
    my ($name, @params) = parse_line(qr/\s+/, 0, $d->value);
    bless {
	name => $name,
	params => [ @params ],
	code => [$d->select]
    }, $class;
}

sub name { shift->{name} }
sub params { @{shift->{params}} }
sub code { @{shift->{code}} }

sub expand {
    my ($self, @args) = @_;
    
    my @rxlist = map {
	my $r = shift @args // '';
	my $q = quotemeta($_);
	[ qr($q), $r ]
    } $self->params;
    map { $self->_node_expand($_->clone, @rxlist) } $self->code;
}

sub _node_expand {
    my ($self, $d, @rxlist) = @_;

    if ($d->type eq 'directive') {
	$d->value($self->_repl($d->value, @rxlist));
    } elsif ($d->type eq 'section') {
	$d->value($self->_repl($d->value, @rxlist));
	foreach my $st ($d->select) {
	    $self->_node_expand($st, @rxlist);
	}
    }
    return $d;
}

sub _repl {
    my ($self, $v, @rxlist) = @_;
    foreach my $rx (@rxlist) {
	$v =~ s{$rx->[0]}{$rx->[1]}g;
    }
    return $v
}

1;

__END__

=head1 NAME    

Apache::Config::Preproc::macro - expand macro statements

=head1 SYNOPSIS

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [ qw(macro) ];

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [ { macro => [ keep => $listref ] } ];

=head1 DESCRIPTION

Processes B<Macro> and B<Use> statements (see B<mod_macro>) in the
Apache configuration parse tree.

B<Macro> statements are removed. Each B<Use> statement is replaced by the
expansion of the macro named in its argument.

The constructor accepts the following arguments:

=over 4

=item B<keep =E<gt>> I<$listref>

List of macro names to exclude from expanding. Each B<E<lt>MacroE<gt>> and
B<Use> statement with a name from I<$listref> as its first argument will be
retained in the parse tree.

As a syntactic sugar, I<$listref> can also be a scalar value. This is
convenient when a single macro name is to be retained.    

=back
    
=head1 SEE ALSO

L<Apache::Config::Preproc>

=cut

