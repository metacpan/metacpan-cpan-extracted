package Chatbot::Alpha::Sort;

our $VERSION = '0.3';

use strict;
use warnings;
use Chatbot::Alpha;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto || 'Chatbot::Alpha::Sort';

	my $self = {
		debug   => 0,
		version => $VERSION,
		@_,
	};

	bless ($self,$class);

	return $self;
}

sub debug {
	my ($self,$msg) = @_;

	# Only show if debug mode is on.
	if ($self->{debug} == 1) {
		print STDOUT "Alpha::Sort::Debug // $msg\n";
	}

	return 1;
}

sub start {
	my $self = shift;

	# $sort->start (
	#    dir   => './my_replies',
	#    files => 'alpha|intact|single',
	#    ext   => 'cba',
	# );
	#  alpha: A.cba to Z.cba, star.cba and other.cba
	# intact: keeps filenames the same, sorts replies internally
	# single: all replies to a single file.

	# Defaults.
	my $method = {
		dir   => '.',
		out   => '.',
		files => 'alpha',
		ext   => 'cba',
		@_,
	};

	# Make outdir if it doesn't exist.
	if ($method->{out} ne '.' && !-e $method->{out}) {
		mkdir ($method->{out});
	}

	# Alpha sorting: sorts from A.cba to Z.cba
	if ($method->{files} eq 'alpha') {
		$self->debug ("Sorting files into alphabetics.");

		# Load ALL replies.
		my $alpha = new Chatbot::Alpha();
		$alpha->load_folder ($method->{dir}, $method->{ext});

		my @labs = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z numbers topics star other);
		foreach my $lab (@labs) {
			$self->{lab}->{$lab} = [];
		}

		# Get an array of all triggers and then sort.
		my @top = keys %{$alpha->{_replies}->{random}};
		@top = sort (@top);

		$self->debug ("Going through triggers...");
		foreach my $trig (@top) {
			$trig =~ s/\(\.\*\?\)/\*/ig;
			$self->debug ("\tTrigger: $trig");
			my $first = substr ($trig,0,1);
			$first = uc($first);
			$first = 'star' if $first eq '*';
			$self->debug ("\t\tFirst: $first");
			if (exists $self->{lab}->{$first}) {
				push (@{$self->{lab}->{$first}}, $trig);
			}
			else {
				push (@{$self->{lab}->{other}}, $trig);
			}
		}

		# Write to files.
		foreach my $lab (keys %{$self->{lab}}) {
			open (WRITE, ">$method->{out}/$lab\.$method->{ext}");

			foreach my $trig (@{$self->{lab}->{$lab}}) {
				$self->debug ("Writing trigger $trig to $lab\.$method->{ext}");

				print WRITE "+ $trig\n";

				$trig =~ s/\*/\(\.\*\?\)/ig;

				my @data = keys (%{$alpha->{_replies}->{random}->{$trig}});
				@data = sort(@data);

				foreach my $item (@data) {
					if ($item =~ /^\d/) {
						print WRITE "- $alpha->{_replies}->{random}->{$trig}->{$item}\n";
					}
					elsif ($item =~ /^(conditions|convo)$/i) {
						my @sub = keys %{$alpha->{_replies}->{random}->{$trig}->{$item}};
						@sub = reverse(@sub);
						foreach my $s (@sub) {
							if ($item eq 'conditions') {
								print WRITE "* ";
							}
							else {
								print WRITE "& ";
							}
							print WRITE "$alpha->{_replies}->{random}->{$trig}->{$item}->{$s}\n";
						}
					}
					elsif ($item eq 'redirect') {
						print WRITE "\@ $alpha->{_replies}->{random}->{$trig}->{redirect}\n";
					}
					elsif ($item eq 'system') {
						print WRITE "# $alpha->{_replies}->{random}->{$trig}->{system}->{codes}\n";
					}
				}

				print WRITE "\n";
			}

			close (WRITE);
		}

		# Write to topics.
		open (TOPICS, ">$method->{out}/topics\.$method->{ext}");
		foreach my $topic (keys %{$alpha->{_replies}}) {
			next if $topic eq 'random';

			my @trigs = keys %{$alpha->{_replies}->{$topic}};
			@trigs = sort(@trigs);

			print TOPICS "> topic $topic\n\n";

			foreach my $trig (@trigs) {
				$self->debug ("Writing trigger $trig to topics\.$method->{ext}");

				$trig =~ s/\(\.\*\?\)/\*/ig;

				print TOPICS "\t+ $trig\n";

				$trig =~ s/\*/\(\.\*\?\)/ig;

				my @data = keys (%{$alpha->{_replies}->{$topic}->{$trig}});
				@data = sort(@data);

				foreach my $item (@data) {
					if ($item =~ /^\d/) {
						print TOPICS "\t- $alpha->{_replies}->{$topic}->{$trig}->{$item}\n";
					}
					elsif ($item =~ /^(conditions|convo)$/i) {
						my @sub = keys %{$alpha->{_replies}->{$topic}->{$trig}->{$item}};
						@sub = reverse(@sub);
						foreach my $s (@sub) {
							if ($item eq 'conditions') {
								print TOPICS "\t* ";
							}
							else {
								print TOPICS "\t& ";
							}
							print TOPICS "$alpha->{_replies}->{$topic}->{$trig}->{$item}->{$s}\n";
						}
					}
					elsif ($item eq 'redirect') {
						print TOPICS "\t\@ $alpha->{_replies}->{$topic}->{$trig}->{redirect}\n";
					}
					elsif ($item eq 'system') {
						print TOPICS "\t# $alpha->{_replies}->{$topic}->{$trig}->{system}->{codes}\n";
					}
				}

				print TOPICS "\n";
			}

			print TOPICS "< topic\n\n";
		}
		close (TOPICS);

		return 1;
	}
	elsif ($method->{files} eq 'intact') {
		# Keeping files intact.
		$self->debug ("Keeping filenames intact");

		opendir (DIR, "$method->{dir}");
		foreach my $file (sort(grep(!/^\./, readdir(DIR)))) {
			next unless $file =~ /\.$method->{ext}/i;

			# Create a new Alpha object for this file.
			my $alpha = new Chatbot::Alpha();
			$alpha->load_file ("$method->{dir}/$file");

			open (WRITE, ">$method->{out}/$file");

			# Do topics first.
			foreach my $topic (keys %{$alpha->{_replies}}) {
				next if $topic eq 'random';
				my @trigs = keys %{$alpha->{_replies}->{$topic}};
				@trigs = sort(@trigs);

				print WRITE "> topic $topic\n\n";

				foreach my $trig (@trigs) {
					$self->debug ("Writing trigger $trig to topics\.$method->{ext}");

					$trig =~ s/\(\.\*\?\)/\*/ig;

					print WRITE "\t+ $trig\n";

					$trig =~ s/\*/\(\.\*\?\)/ig;

					my @data = keys (%{$alpha->{_replies}->{$topic}->{$trig}});
					@data = sort(@data);

					foreach my $item (@data) {
						if ($item =~ /^\d/) {
							print WRITE "\t- $alpha->{_replies}->{$topic}->{$trig}->{$item}\n";
						}
						elsif ($item =~ /^(conditions|convo)$/i) {
							my @sub = keys %{$alpha->{_replies}->{$topic}->{$trig}->{$item}};
							@sub = reverse(@sub);
							foreach my $s (@sub) {
								if ($item eq 'conditions') {
									print WRITE "\t* ";
								}
								else {
									print WRITE "\t& ";
								}
								print WRITE "$alpha->{_replies}->{$topic}->{$trig}->{$item}->{$s}\n";
							}
						}
						elsif ($item eq 'redirect') {
							print WRITE "\t\@ $alpha->{_replies}->{$topic}->{$trig}->{redirect}\n";
						}
						elsif ($item eq 'system') {
							print WRITE "\t# $alpha->{_replies}->{$topic}->{$trig}->{system}->{codes}\n";
						}
					}

					print WRITE "\n";
				}

				print WRITE "< topic\n\n";
			}

			# Now, normal replies.
			my @trigs = keys %{$alpha->{_replies}->{random}};
			@trigs = sort(@trigs);

			foreach my $trig (@trigs) {
				$self->debug ("Writing trigger $trig to topics\.$method->{ext}");

				$trig =~ s/\(\.\*\?\)/\*/ig;

				print WRITE "+ $trig\n";

				$trig =~ s/\*/\(\.\*\?\)/ig;

				my @data = keys (%{$alpha->{_replies}->{random}->{$trig}});
				@data = sort(@data);

				foreach my $item (@data) {
					if ($item =~ /^\d/) {
						print WRITE "- $alpha->{_replies}->{random}->{$trig}->{$item}\n";
					}
					elsif ($item =~ /^(conditions|convo)$/i) {
						my @sub = keys %{$alpha->{_replies}->{random}->{$trig}->{$item}};
						@sub = reverse(@sub);
						foreach my $s (@sub) {
							if ($item eq 'conditions') {
								print WRITE "* ";
							}
							else {
								print WRITE "& ";
							}
							print WRITE "$alpha->{_replies}->{random}->{$trig}->{$item}->{$s}\n";
						}
					}
					elsif ($item eq 'redirect') {
						print WRITE "\@ $alpha->{_replies}->{random}->{$trig}->{redirect}\n";
					}
					elsif ($item eq 'system') {
						print WRITE "# $alpha->{_replies}->{random}->{$trig}->{system}->{codes}\n";
					}
				}

				print WRITE "\n";
			}

			close (WRITE);
		}
		closedir (DIR);

		return 1;
	}
	elsif ($method->{files} eq 'single') {
		$self->debug ("Merging all files into one");

		my $alpha = new Chatbot::Alpha();
		$alpha->load_folder ($method->{dir},$method->{ext});

		open (WRITE, ">$method->{out}/sorted.cba");

		# Do topics first.
		foreach my $topic (keys %{$alpha->{_replies}}) {
			next if $topic eq 'random';
			my @trigs = keys %{$alpha->{_replies}->{$topic}};
			@trigs = sort(@trigs);

			print WRITE "> topic $topic\n\n";

			foreach my $trig (@trigs) {
				$self->debug ("Writing trigger $trig to topics\.$method->{ext}");

				$trig =~ s/\(\.\*\?\)/\*/ig;

				print WRITE "\t+ $trig\n";

				$trig =~ s/\*/\(\.\*\?\)/ig;

				my @data = keys (%{$alpha->{_replies}->{$topic}->{$trig}});
				@data = sort(@data);

				foreach my $item (@data) {
					if ($item =~ /^\d/) {
						print WRITE "\t- $alpha->{_replies}->{$topic}->{$trig}->{$item}\n";
					}
					elsif ($item =~ /^(conditions|convo)$/i) {
						my @sub = keys %{$alpha->{_replies}->{$topic}->{$trig}->{$item}};
						@sub = reverse(@sub);
						foreach my $s (@sub) {
							if ($item eq 'conditions') {
								print WRITE "\t* ";
							}
							else {
								print WRITE "\t& ";
							}
							print WRITE "$alpha->{_replies}->{$topic}->{$trig}->{$item}->{$s}\n";
						}
					}
					elsif ($item eq 'redirect') {
						print WRITE "\t\@ $alpha->{_replies}->{$topic}->{$trig}->{redirect}\n";
					}
					elsif ($item eq 'system') {
						print WRITE "\t# $alpha->{_replies}->{$topic}->{$trig}->{system}->{codes}\n";
					}
				}

				print WRITE "\n";
			}

			print WRITE "< topic\n\n";
		}

		# Now, normal replies.
		my @trigs = keys %{$alpha->{_replies}->{random}};
		@trigs = sort(@trigs);

		foreach my $trig (@trigs) {
			$self->debug ("Writing trigger $trig to topics\.$method->{ext}");

			$trig =~ s/\(\.\*\?\)/\*/ig;

			print WRITE "+ $trig\n";

			$trig =~ s/\*/\(\.\*\?\)/ig;

			my @data = keys (%{$alpha->{_replies}->{random}->{$trig}});
			@data = sort(@data);

			foreach my $item (@data) {
				if ($item =~ /^\d/) {
					print WRITE "- $alpha->{_replies}->{random}->{$trig}->{$item}\n";
				}
				elsif ($item =~ /^(conditions|convo)$/i) {
					my @sub = keys %{$alpha->{_replies}->{random}->{$trig}->{$item}};
					@sub = reverse(@sub);
					foreach my $s (@sub) {
						if ($item eq 'conditions') {
							print WRITE "* ";
						}
						else {
							print WRITE "& ";
						}
						print WRITE "$alpha->{_replies}->{random}->{$trig}->{$item}->{$s}\n";
					}
				}
				elsif ($item eq 'redirect') {
					print WRITE "\@ $alpha->{_replies}->{random}->{$trig}->{redirect}\n";
				}
				elsif ($item eq 'system') {
					print WRITE "# $alpha->{_replies}->{random}->{$trig}->{system}->{codes}\n";
				}
			}

			print WRITE "\n";
		}

		close (WRITE);

		return 1;
	}
}

1;
__END__

=head1 NAME

Chatbot::Alpha::Sort - Alphabetic sorting for Chatbot::Alpha documents.

=head1 SYNOPSIS

  use Chatbot::Alpha::Sort;
  
  # Create a new sorter.
  my $sort = new Chatbot::Alpha::Sort();
  
  # Sort your files.
  $sort->start (
     dir => './before',
     out => './after',
     ext => 'cba',
  );

=head1 DESCRIPTION

Chatbot::Alpha::Sort can take your numerous unsorted Alpha documents, and create nicely formatted
documents from A.cba to Z.cba with triggers sorted alphabetically within each document.

=head1 METHODS

=head2 new (ARGUMENTS)

Creates a new Chatbot::Alpha::Sort object. You should only need one object, since each sort request
creates its own Chatbot::Alpha, unless you intend to run multiple sorts at the same time.

Returns a Chatbot::Alpha::Sort instance.

=head2 version

Returns the version number of the module.

=head2 start (ARGUMENTS)

Starts the sorting process. ARGUMENTS is a hash that you must pass in to tell the module how to do things. The arguments
are as follows:

  dir => DIRECTORY
     The directory at which your original Alpha documents
     can be found. Defaults to CWD.
  out => DIRECTORY
     Another directory for which your newly formatted Alpha
     documents will be written to. Defaults to CWD.
  ext => EXTENSION
     The file extension of your Alpha documents. Defaults
     to cba
  files => SORT_TYPE
     The sorting method for which your new files will be sorted.
     See below for the sort types.

=head1 SORT TYPES (FILES)

B<alpha>
Sorts the files alphabetically. Will create files "A.cba" through "Z.cba", as well as "star.cba" and "other.cba",
and a "topics.cba" to keep all topics together. Triggers within each file are sorted alphabetically.

B<intact>
Keeps your original filename structure intact; only sorts triggers alphabetically within each file (topics go
to the top of the file's contents).

B<single>
Takes ALL your Alpha documents and merges them into one single file. Will write the finished file to "sorted.cba"
in the OUT directory. Topics are written first.

=head1 CHANGES

  Version 0.2
  - Added sorting with "keep filenames intact" as well as "single filename"
  
  Version 0.1
  - Initial release.

=head2 SEE ALSO

L<Chatbot::Alpha>

=head1 KNOWN BUGS

No bugs have been discovered at this time.

=head1 AUTHOR

Casey Kirsle, http://www.cuvou.com/

=head1 COPYRIGHT AND LICENSE

    Chatbot::Alpha - A simple chatterbot brain.
    Copyright (C) 2005  Casey Kirsle

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
