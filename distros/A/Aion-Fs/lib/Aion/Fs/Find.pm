package Aion::Fs::Find;

use common::sense;
use Aion::Fs qw//;

use overload
	'<>' => sub { shift->next },
	'&{}' => sub {
		my ($self) = @_;
		sub { $self->next }
	},
	'@{}' => sub {
		my ($self) = @_;
		my @paths; my $path;
		push @paths, $path while defined($path = $self->next);
		\@paths
	},
;

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

sub next {
	my ($self) = @_;
	my $path = eval {
		my $files = $self->{files};
	    FILE: while(@$files) {
			my $path = shift @$files;

			if(-d $path) {
				my $indir = 1;
				for my $noenter (@{$self->{noenters}}) {
					local $_ = $path;
					$indir = 0, last if $noenter->();
				}

				if($indir) {
					if(opendir my $dir, $path) {
						my @file;
						while(my $f = readdir $dir) {
							push @file, Aion::Fs::joindir($path, $f) if $f !~ /^\.{1,2}\z/;
						}
						push @$files, sort @file;
						closedir $dir;
					}
					else {
						local $_ = $path;
						$self->{errorenter}->();
					};
				}
			}
			
			my $valid = 1;
			for my $filter (@{$self->{filters}}) {
				local $_ = $path;
				$valid = 0, last unless $filter->();
			}

			return $path if $valid;
		}

		undef
	};
	
	if($@) {
		die if ref $@ ne "Aion::Fs::stop";
	}

	$path
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Fs::Find - file search iterator for Aion::Fs#find

=head1 SYNOPSIS

	use Aion::Fs::Find;
	
	my $iter = Aion::Fs::Find->new(
		files => ["."],
		filters => [],
		errorenter => sub {},
		noenters => [],
	);
	
	my @files;
	while (<$iter>) {
	    push @files, $_;
	}
	
	\@files # --> ["."]

=head1 DESCRIPTION

File search iterator for the C<find> adapter function from the C<Aion::Fs> module.

Not intended to be used separately.

It has overloaded C<< E<lt>E<gt> >>, C<@{}> and C<&{}> operators.

=head1 SUBROUTINES

=head2 new (%params)

Constructor.

=head2 next ()

Next iteration.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Fs::Find module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
