package App::Glacier::Command::ListVault;

use strict;
use warnings;
use App::Glacier::Command;
use parent qw(App::Glacier::Command);
use App::Glacier::DateTime;
use App::Glacier::Timestamp;
use App::Glacier::Glob;
use App::Glacier::Directory qw(:status);

=head1 NAME

glacier ls - list vaults or archives

=head1 SYNOPSIS

B<glacier ls>
[B<-SUdlhtr>]
[B<--human-readable>]
[B<--sort=>B<none>|B<name>|B<time>|B<size>]
[B<--reverse>]
[B<--time-style=>B<default>|B<full-iso>|B<long-iso>|B<iso>|B<locale>|B<+I<FORMAT>>]    
[I<VAULT>]
[I<FILE>...]    

=head1 DESCRIPTION

Displays information about vaults and files.

Used without arguments, displays the list of existing vaults.

With one argument, lists files in the named vault, unless B<-d> is
also specified, in which case, lists information about this vault only.

With two or more arguments, lists files in I<VAULT> with names matching
I<FILE> arguments.  The latter can contain version numbers and globbing
patterns.  See B<glacier>(1), section B<On file versioning>, for the
information about file versioning scheme.   

=head1 OPTION

=over 4
    
=item B<-S>
    
=item B<--sort=size>

Sort by file size, largest first.
    
=item B<-U>

=item B<--sort=none>

Don't sort names.    
    
=item B<-d>, B<--directory>

List just the names of vaults, rather than listing their contents.  This is
the default if no arguments are supplied.    
    
=item B<-l>

Print additional information.  For vaults: total size, number of archives
in vault, creation date, and the vault name.  For files: file size, total
number of stored versions, creation date, and the file name.
    
=item B<-t>

=item B<--sort=time>

Sort by modification time, newest first.
        
=item B<-h>, B<--human-readable>

Append a size letter to each size (B<K>, B<M>, or B<G>).  Powers of 1024
are used, so that B<M> stands for 1,048,576 bytes. 
    
=item B<--sort=>I<KEY>

Sort output according to I<KEY>, which is one of: B<none>, B<name>, B<time>,
B<size>.  Default is B<name>.
    
=item B<-r>, B<--reverse>

Reverse the sort order.  E.g. with B<-t>, list youngest files first.    
    
=item B<--time-style=>I<STYLE>

List timestamps in style STYLE.  The STYLE should be one of the
following:

=over 8

=item B<+I<FORMAT>>

List timestamps using I<FORMAT>, which is interpreted as the I<format>
argument to B<strftime>(3) function.
    
=item B<default>

Default format.  For timestamps not older than 6 month: month, day, hour
and minute, e.g.: "May 23 15:00".  For older timestamps: month, day, and
year, e.g.: "May 23  2017".
    
=item B<full-iso>

List timestamps in full using ISO 8601 date, time, and time zone format with
nanosecond precision, e.g., "2017-05-23 15:53:10.633308971 +0000".  This style
is equivalent to "B<+%Y-%m-%d %H:%M:%S.%N %z>".

=item B<long-iso>

List ISO 8601 date and time in minutes, e.g., "2017-05-23 15:53".  Equivalent
to "B<+%Y-%m-%d %H:%M>".    
    
=item B<iso>

B<GNU ls>-compatible "iso": ISO 8601 dates for non-recent timestamps (e.g.,
"2017-05-23"), and ISO 8601 month, day, hour, and minute for recent
timestamps (e.g., "03-30 23:45").  Timestamp is considered "recent", if it
is not older than 6 months ago.    

=item B<locale>

List timestamps in a locale-dependent form.  This is equivalent to B<+%c>.

=back

=back
    
=head1 SEE ALSO

B<glacier>(1),    
B<strftime>(3).

=cut    

sub getopt {
    my ($self, %opts) = @_;
    my %sort_vaults = (
	none => undef,
	name => sub {
	    my ($a, $b) = @_;
	    $a->{VaultName} cmp $b->{VaultName}
	},
	time => sub {
	    my ($a, $b) = @_;
	    $a->{CreationDate}->epoch <=> $b->{CreationDate}->epoch;
	},
	size => sub {
	    my ($a, $b) = @_;
	    $a->{SizeInBytes} <=> $b->{SizeInBytes}
	}
    );
    my %sort_archives = (
	none => undef,
	name => sub {
	    my ($a, $b) = @_;
	    $a->{FileName} cmp $b->{FileName}
	},
	time => sub {
	    my ($a, $b) = @_;
	    $a->{CreationDate}->epoch <=> $b->{CreationDate}->epoch;
	},
	size => sub {
	    my ($a, $b) = @_;
	    $a->{Size} <=> $b->{Size}
	}
    );
    $self->{_options}{sort} = 'name';
    my $rc = $self->SUPER::getopt(
	'directory|d' => \$self->{_options}{d},
	'l' => \$self->{_options}{l},
	'sort=s' => \$self->{_options}{sort},
	't' => sub { $self->{_options}{sort} = 'time' },
	'S' => sub { $self->{_options}{sort} = 'size' },
	'U' => sub { $self->{_options}{sort} = 'none' },
	'human-readable|h' => \$self->{_options}{h},
	'reverse|r' => \$self->{_options}{r},
	'time-style=s' => sub { $self->set_time_style_option($_[1]) },
	%opts);
    return $rc unless $rc;

    $self->{_options}{d} = 1 if (@ARGV == 0);

    if (defined($self->{_options}{sort})) {
	my $sortfun = $self->{_options}{d}
	                ? \%sort_vaults : \%sort_archives;
	$self->abend(EX_USAGE, "unknown sort field")
	    unless exists($sortfun->{$self->{_options}{sort}});
	$self->{_options}{sort} = $sortfun->{$self->{_options}{sort}};
    }
}
    
sub run {
    my $self = shift;
    
    if ($self->{_options}{d}) {
	$self->list_vaults($self->get_vault_list(@_));
    } else {
	$self->list_archives($self->get_vault_inventory(@_));
    }
}

sub get_vault_list {
    my $self = shift;

    my $glob = new App::Glacier::Glob(@_);
    if ($glob->is_literal) {
	return [$self->describe_vault(@_)];
    } else {
	my $res = $self->glacier_eval('list_vaults');
	if ($self->lasterr) {
	    $self->abend(EX_FAILURE, "can't list vaults: ",
			 $self->last_error_message);
	}
	return [map { timestamp_deserialize($_) }
	           $glob->filter(sub {
		                    my ($x) = @_;
				    return $x->{VaultName}
				 }, @$res)];
    }
}

sub list_vaults {
    my ($self, $ref) = @_;

    foreach my $v (defined($self->{_options}{sort}) ?
		        sort {
			    &{$self->{_options}{sort}} 
			      ($self->{_options}{r} ? ($b, $a) : ($a, $b))
		        } @$ref
		      : @$ref) {
	$self->show_vault($v);
    }
}

sub format_size {
    my ($self, $size, $width) = @_;
    my $suf = '';
    if ($self->{_options}{h}) {
	my @suffixes = ('K', 'M', 'G');
	while ($size >= 1024 && @suffixes) {
	    $size /= 1024;
	    $suf = shift @suffixes;
	}
    }
    my $l = ($width || 10);
    return sprintf("%*.*s", $l, $l, int($size) . $suf);
}

sub show_vault {
    my ($self, $vault) = @_;
    if ($self->{_options}{l}) {
	printf("%8s % 8u %s %-24s\n",
	       $self->format_size($vault->{SizeInBytes}),
	       $vault->{NumberOfArchives},
	       $vault->{CreationDate}->canned_format($self->{_options}{time_style}),
	       $vault->{VaultName});
    } else {
	print $vault->{VaultName},"\n";
    }
}

sub list_archives {
    my ($self, $ref) = @_;

    foreach my $v (defined($self->{_options}{sort}) ?
		        sort {
			    &{$self->{_options}{sort}} 
			      ($self->{_options}{r} ? ($b, $a) : ($a, $b))
		        } @$ref
		      : @$ref) {
	$self->show_archive($v);
    }
}

sub show_archive {
    my ($self, $arch) = @_;

    if ($self->{_options}{l}) {
	printf("%8s % 8u %s %-24s\n",
	       $self->format_size($arch->{Size}),
	       $arch->{FileTotalVersions},
	       $arch->{CreationDate}->canned_format($self->{_options}{time_style}),
	       $arch->{FileName});
	
    } else {
	print "$arch->{FileName}\n";
    }
}

sub get_vault_inventory {
    my ($self, $vault_name, @file_list) = @_;
    my $dir = $self->directory($vault_name);
    $self->abend(EX_FAILURE, "no such vault: $vault_name")
	unless defined $dir;

    if ($dir->status == DIR_PENDING) {
	require App::Glacier::Command::Sync;	
	my $sync = new App::Glacier::Command::Sync;
	$sync->sync($vault_name) or exit(EX_TEMPFAIL);
    }
    
    my @glob;
    if (@file_list) {
	my %vtab;
	my @unversioned;
	foreach my $f (@file_list) {
	    if ($f =~ /^(?<pat>.+?)(?<!\\);(?<ver>\d+)$/) {
		push @{$vtab{$+{ver}}}, $+{pat};
	    } else {
		push @unversioned, $f;
	    }
	}

	push @glob, [ new App::Glacier::Glob(@unversioned), 1 ]
	    if @unversioned;
	while (my ($ver, $pat) = each %vtab) {
	    push @glob, [ new App::Glacier::Glob(@$pat), $ver ];
	}
    } else {
	push @glob, [ new App::Glacier::Glob, 1 ];
    }
    
    my @result;
    $dir->foreach(sub {
	my ($file, $info) = @_;
	foreach my $ver (map { $_->[0]->match($file) ? $_->[1] : () } @glob) {
	    next unless $ver <= @$info;
	    push @result, {@{[ %{$info->[$ver-1]},
                               ( 'FileName' => $file,
				 'FileVersion' => $ver,
				 'FileTotalVersions' => $#{$info} + 1 ) ]}};
	}
		  });
    
    return \@result;
}

1;
