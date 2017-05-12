package Config::ApacheExtended;

use Parse::RecDescent;
use Config::ApacheExtended::Grammar;
use IO::File;
use Scalar::Util qw(weaken);
use Text::Balanced qw(extract_variable);
use File::Spec::Functions qw(splitpath catpath abs2rel rel2abs file_name_is_absolute);
use Carp qw(croak cluck);
use strict;
BEGIN {
	use vars qw ($VERSION $DEBUG);
	$VERSION	= sprintf("%d.%02d", q$Revision: 1.15 $ =~ /(\d+)/g);
	$DEBUG		= 0;
}

=pod

=head1 NAME

Config::ApacheExtended - use extended apache format config files

=head1 SYNOPSIS

=for example begin

  use Config::ApacheExtended
  my $conf = Config::ApacheExtended->new(source => "t/parse.conf");
  $conf->parse() or die "Unsuccessful Parsing of config file";

  # Print out all the Directives
  foreach ($conf->get())
  {
      print "$_ => " . $conf->get($_) . "\n";
  }

  # Show all the blocks at the root
  foreach ($conf->block())
  {
      foreach ($conf->block($_))
      {
          print $_->[0] . " => " . $_->[1] . "\n";
          foreach ($conf->block(@$_))
          {
              my $block = $_;
              foreach ($block->get())
              {
                  print "$_ => " . $block->get($_) . "\n";
              }
          }
      }
  }

=for example end

=head1 DESCRIPTION

This module is used to parse a configuration file similar to that of the
Apache webserver (see http://httpd.apache.org for more details).  This module
provides several extensions to that syntax, namely variable substitution and
Hereto documents.  Other features include, value inheritance, directive and
block validation, and include support.  This module also handles quoted strings
and split lines properly.

=head1 METHODS

=head2 new

Usage     : Config::AapcheExtended->new( I<%options> )

Purpose   : Construct a new Config::ApacheExtended object

Returns   : A new Config::ApacheExtended object, or undef on
            error.

=head3 Arguments :

=over 4

=item source - I<path string>

The relative or absolute path to the configuration file.
If a relative path is given, it is resolved using File::Spec::rel2abs

=item expand_vars - I<boolean>

Turn on variable expansion support. (See L</"VARIABLE SUBSTITUTION">)

Defaults to B<OFF>.

=item conf_root - I<path string>

The directory to use as the base for relative path resolutions (i.e. for include statements)

=item root_directive - I<string>

If this option is set then it will be used as conf_root.
This is handy if parsing an apache config file set it to "ServerRoot".

=item honor_include - I<boolean>

Set this option to false to turn off include support. 

Defaults to B<ON>.

=item inherit_vals - I<boolean>

If this option is set value inheritance will be enabled.

Defaults to B<OFF>.

=item ignore_case - I<boolean>

If this option is turned off then directives and block names are case sensitive.

Defaults to B<ON>.

=item die_on_nokey - I<boolean>

If this option is turned on then get() will die if the given key is not found,
when this option is off get() will return undef when the key is not found.

Defaults to B<OFF>.

=item die_on_noblock - I<boolean>

Same as die_on_noblock, except for the block() method.
These two options are here to help emulate behaviour in
Config::ApacheFormat.

Defaults to B<OFF>.

=item valid_directives - I<Array Ref>

This option allows you to specify a list of valid directives.
If the parser comes across any directive not in this list, it will fail.

=item valid_blocks - I<Array Ref>

This option is the same as valid_directives except it applies to block
specifiers.

=back

=cut

{
	my %_def_params = (
		_expand_vars		=> 0,
		_conf_root			=> undef,
		_root_directive		=> undef,
		_honor_include		=> 1,
		_inherit_vals		=> 0,
		_ignore_case		=> 1,
		_die_on_nokey		=> 0,
		_die_on_noblock		=> 0,
		_valid_directives	=> undef,
		_valid_blocks		=> undef,
		_source				=> undef,
	);

	sub _default_parameters { %_def_params; }
}
	
sub new
{
	my $cl = shift;
	my %args = @_;
	my $class = ref($cl) || $cl;

	my $self = {
		ref($cl) ? %$cl : $class->_default_parameters(),
		(map { ("_$_" => $args{$_}) } keys %args),
		_data	=> {},
	};

	# automatically add the root_directive to the valid_directives list if there is one.
	if ( defined($self->{_valid_directives}) && defined($self->{_root_directive}) )
	{
		push(@{$self->{_valid_directives}}, $self->{_root_directive});
	}

	bless($self,$class);		
	($self->{_source},$self->{_conf_root}) = _resolveSource($self->{_source}, $self->{_conf_root});
	return $self;
}

sub _resolveSource
{
	my $source = shift;
	my $root = shift;
	my $conf_root;

	return unless defined($source);

	if ( !file_name_is_absolute($source) )
	{
		$source = rel2abs($source, $root);
	}

	my @path_parts;
	@path_parts = splitpath($source);
	$path_parts[-1] = '';
	$conf_root = defined($root) ? $root : catpath(@path_parts);

	return ($source,$conf_root);
}

=pod

=head2 parse

=over 4

Usage     : $conf->parse( I<source> );

Purpose   : Causes the Config::ApacheExtended
            object to parse the given source.

Returns   : undef on error, number of top level
            directives found if successful.

Argument  : B<Optional.> The source to parse. This argument gives
            some more options than what the source argument to new()
            allows.  This can be a filehandle (GLOB or L<IO::File>),
            a relative or absolute path string, or a reference to a
            scalar holding the contents to parse.

Throws    : Croaks on unresolvable path string.


For example:

  my $contents = "DirectiveA valueA\n" .
    "DirectiveB valueB\n" .
    "<BlockC valuec>\n" .
      "DirectiveD valueD\n" .
    "</BlockC>\n";

  my $conf = Config::ApacheExtended->new();
  $conf->parse(\$contents);

=back

=cut

sub parse
{
	my $self = shift;
	my $source = shift;
	$self->{_current_block}		= $self->{_data};
	$self->{_previous_blocks}	= [];

	my $contents;

	if ( defined($source) && (ref($source) eq 'SCALAR' ) )
	{
		$contents = \$source;
	}
	elsif ( defined($source) && ref($source) =~ m/GLOB|IO::File/ )
	{
		$contents = join('', <$source>);
	}
	else
	{
		my $fh = IO::File->new($self->{_source}, "r") or croak "Could not open source [ " . $self->{_source} . " ] : $!\n";
		$contents = join('', <$fh>);
		$fh->close();
	}
	
#	my $parser = Parse::RecDescent->new(join('', <DATA>));
	my $parser = Config::ApacheExtended::Grammar->new();

	my $result = $parser->grammar($contents,1,$self);

	unless ( defined($result) )
	{
		return undef;
	}

	delete $self->{_current_block};
	delete $self->{_previous_blocks};

	$self->_substituteValues() if $self->{_expand_vars};
	$self->{_parse_result} = $result;
	return scalar(keys(%{$self->{_data}}));
}

sub include
{
	return $_[0]->{_honor_include};
}

sub _loadFile
{
	my $self = shift;
	my $file = shift;
	my $contents = "";
	$file = (_resolveSource($file,$self->{_conf_root}))[0];
	if ( -d $file )
	{
		opendir(INCD, $file) or cluck("Error opening include directory [ $file ] : $!\n");
		my @files = map { "$file/$_" } grep { -f "$file/$_" } readdir(INCD);
		closedir(INCD);
		$contents .= $self->_loadFile($_) for @files;
	}
	elsif ( -r $file )
	{
		my $fh = IO::File->new($file, "r");
		unless ( $fh )
		{
			cluck("Could not open [ $file ] for reading: $!\n");
			return '';
		}
		else
		{
			local $/ = undef;
			$contents = <$fh>;
		}
	}
	else
	{
		cluck("Could not find file [ $file ]\n");
		return '';
	}

#	open(TMP, '>/tmp/contents.txt');
#	print TMP $contents;
#	close(TMP);
	return $contents;
}

sub _validateKey
{
	my $self = shift;
	my($key,$valids) = @_;
	
	return 1 unless defined($valids);
	my $temp = $self->{_ignore_case} ? "(?i)" : "";
	return 1 if grep { $key =~ qr/$temp$_/ } @$valids;
	return undef;
}

sub newDirective
{
	my $self = shift;
	my($dir,$vals) = @_;
	$dir = lc $dir if $self->{_ignore_case};
	return undef unless $self->_validateKey($dir,$self->{_valid_directives});
	$self->{_current_block}->{$dir} = $vals;
	if ( defined($self->{_root_directive}) && $self->{_root_directive} eq $dir )
	{
		$self->{_root_directive} = $vals->[0];
	}
	return 1;
}

sub beginBlock
{
	my $self = shift;
	my($block,$vals) = @_;
	$block = lc $block if $self->{_ignore_case};
	return undef unless $self->_validateKey($block,$self->{_valid_blocks});
	my $ident = $block;
	if ( defined($vals) && @$vals )
	{
		$ident = shift @$vals;
		$ident = lc $ident if $self->{_ignore_case};
	}
	my $new_block = {};
	$self->{_current_block}->{$block}->{$ident} = $new_block;
	push(@{$self->{_previous_blocks}}, $self->{_current_block});
	$self->{_current_block} = $new_block;
	return 1;
}

sub endBlock
{
	my $self = shift;
	if ( @{$self->{_previous_blocks}} )
	{
		$self->{_current_block} = pop @{$self->{_previous_blocks}};
	}

	return 1;
}

sub end
{
	$_[0]->{_current_block} = undef;
	return 1;
}

sub _substituteValues
{
	my $self = shift;
	my $data = $self->{_data};

	foreach my $key ($self->get())
	{
		my @vals = $self->get($key); #@{$data->{$key}};
		for ( my $i = 0; $i < @vals; $i++ )
		{
			my $newval = $vals[$i];
			while( my $varspec = extract_variable($newval, qr/(?:.*?)(?=[\$\@])/) )
			{
				my($type,$var,$idx) = $varspec =~ m/^([\$\@])(.*?)(?:\[(\d+)\])?$/;
				$idx ||= 0;
				my $pattern;
				($pattern = $varspec) =~ s/([^\w\s])/\\$1/g;
				$var = $self->{_ignore_case} ? lc $var : $var;
				my @lval = $self->get($var);
				if ( !@lval )
				{
					warn "No Value for $varspec found\n";
					last;
				}

				if ( $type eq '$' )
				{
					$data->{$key}->[$i] =~ s/$pattern/$lval[$idx]/g;
				}
				elsif ( $type eq '@' )
				{
					if ( $data->{$key}->[$i] =~ m/^$pattern$/ )
					{
						splice(@{$data->{$key}}, $i, 1, @lval);
					}
					else
					{
						$data->{$key}->[$i] =~ s/$pattern/join($", @lval)/eg;
					}
				}
			}
		}
	}
}

=pod

=head2 get

=over 4

Usage     : get( I<DirectiveName> )

Purpose   : Retrieve a value, or a list of directives in
            current block.

Returns   : If a directive has a single value associated with it
            get() returns that value as a scalar regardless of
            context, if a directive has more than one value and
            get() is called in a list context then a list is
            returned, if get() is called in a scalar context, then
            an anonymous array is returned. If no directive can be
            found an empty list or undef is returned respective of
            the context in which get() was called.  If no
            directive is given then a list of keys in the current
            block is returned.

Argument  : B<Optional.> Directive name

Throws    : Only if die_on_nokey is turned B<ON>.

See Also  : block()

For Example:

  # Print out a list of all this block's directives
  my @directives = $conf->get();
  map { print "$_\n" } @directives;

  my @vals = $conf->get('Bar') or die "Could not find 'Bar'";
  print join(", ", @vals);

  my $vals = $conf->get('Bar');
  print join(", ", @$vals);

=back

=cut

sub get
{
	my $self = shift;
	my $key = shift;
	my $data = $self->{_data};
	return unless defined wantarray;

	unless(defined($key))
	{
#		return map { $_ if ref($data->{$_}) ne 'HASH' } keys(%$data);
		return grep { ref($data->{$_}) ne 'HASH' } keys(%$data);
	}

	$key = lc $key if $self->{_ignore_case};
	return undef if ref($data->{$key}) eq 'HASH';

	if ( exists($data->{$key}) )
	{
		if( scalar(@{$data->{$key}}) == 1 ) 
		{
			return $data->{$key}->[0];
		}
		else
		{
			return wantarray ? @{$data->{$key}} : [ @{$data->{$key}} ];
		}
	}
	elsif ( $self->{_inherit_vals} && exists($self->{_parent}) )
	{
		return wantarray ? ($self->{_parent}->get($key)) : $self->{_parent}->get($key);
	}
	else
	{
		return wantarray ? () : undef;
	}
}

=pod

=head2 block

=over 4

Usage     : block( I<< BlockType => BlockName >> )

Purpose   : Retrieve a list of all blocks in the current block,
            a list of a given block type in the current block,
            or a specific block.

Returns   : If no BlockType is given, then a list of available
            BlockTypes is returned.  If given a BlockType then
            block() returns a list of anonymous arrays, which
            contain the block type followed by the block name
            of all the blocks of the given type in the current
            block.  This is so that retrieving a block from the
            list is more convenient.  If a specific block is
            requested, then a new Config::ApacheExtended object
            is returned.  This object only contains the values
            and blocks associated with the requested block.


Argument  : B<Optional.> BlockType <Optional.> BlockName 

Throws    : Only if die_on_noblock is turned B<ON>.

See Also  : get()

For Example:

  # Print out a list of all the BlockTypes in this block
  my @blocktypes = $conf->block();
  map { print "$_\n" } @blocktypes;

  # Print out all the block names of each BlockType
  foreach my $blocktype (@blocktypes)
  {
      my @blocks = $conf->block($blocktype);
      # Print the block name and list of keys for each block
	  print "$blocktype:\n";
	  foreach my $blockspec (@blocks)
	  {
	      print "\t" . $blockspec->[1] . "\n";
		  my $block = $conf->block(@$blockspec);
		  map { print "\t\t$_\n" } ($block->get());
	  }
  }

=back

=cut

sub block
{
	my $self = shift;
	my ($type,$key) = @_;
	my $data = $self->{_data};

	unless (defined($type))
	{
		return grep { ref($data->{$_}) eq 'HASH' } keys(%$data);
	}

	$type = lc $type;
	return undef unless ref($data->{$type}) eq 'HASH';

	unless ( defined($key) )
	{
		return map { [$type, $_]  } keys(%{$data->{$type}});
	}

	$key = lc $key;
	return undef if !exists($data->{$type}->{$key});
	return $self->_createBlock( $data->{$type}->{$key} );
}

=pod

=head2 as_hash

 Usage     : as_hash()
 Purpose   : Returns the current block's data as a hash
 Returns   : a copy of the current block's data as a hash ref.
 Comments  : Don't use this.  It is Dangerous.

=cut

sub as_hash
{
	my $self = shift;
	return { %{$self->{_data}} };
}

sub _createBlock
{
	my $self = shift;
	my $data = shift;
	my $block = bless { %{$self} }, ref($self);
	$block->{_data} = {%$data};

	if ( $self->{_inherit_vals} )
	{
		my $parent = $self;
		weaken($parent);
		$block->{_parent} = $parent;
	}

	$block->_substituteValues() if $self->{_expand_vars};
	return $block;
}

1;

=head1 VARIABLE SUBSTITUTION

It just occured to me that this section has been omitted for some time. Sorry.
Variable substitution is supported in one of three ways.  Given the configuration:

  ValList1 myval1 myval2
  ValList2 myval3 myval4

  MyVal @ValList1 @ValList2
  OddVal thatval1 @ValList1 thatval2
  Stringification "The (@ValList1) is a list of two values"
  AnotherVal $ValList1
  YetAnotherVal $ValList2[1]

Retrieving C<MyVal> will yield a list with 4 values namely: I<myval1, myval2, myval3, myval4>.
Retrieving C<OddVal> will also yield a list with 4 values: I<thatval1, myval1, myval2, thatval2>.
Retrieving C<AnotherVal> will yeild I<myval1>.  Retrieving C<YetAnotherVal> will yield: I<myval4>.
Retrieving C<Stringification> will yield the string: I<The (myval1 myval2) is a list of two values>.

So this leads to the conclusion that:

=over 4

=item *

The "$" prefix substitutes the first/only value of another directive.

=item *

The "$" prefix used with the index I<N> after the directive name will substitute the Nth value of the other directive.
Indexes are zero indexed just as Perl array indexes are.

=item *

The "@" prefix substitutes the entire value list of the other directive in place.

=item *

The "@" prefix will substitute the entire value list joined on the C<$LIST_SEPARATOR> if it occurs within a quoted string.
B<NOTE:> That C<"@SomeVal"> will not cause stringification of the list.  I'm working on this.

=back

This behaviour has only slightly changed from 1.15 to 1.16.  The difference is that the "@" prefix now causes the entire list
to be substituted rather than having the values joined with the C<$LIST_SEPARATOR> character.
Also note that substitution B<WILL> occur inside single quotes.  This is a limitation of the current implementation,
as I do not have enough hints at substitution time to know whether the values where inside single or double quotes.
I welcome patches/suggestions to fix this.

=head1 BUGS

This not really a bug, more of a Todo, however This module does not currently provide
access to multiple block "names" (i.e. <BlockType blockval1 blockval2>...</BlockType>)
However, it will parse these blocks properly.  The only thing that needs to be done is
to provide space in the data structure for these values, they were not important to me,
so I didn't see the need.  However, I am willing to accept patches.

Other than that, I have found no bugs, but I'm sure there are some lurking about.
(Example code is for the most part untested, [I'm working on this, I just wanted
to get the documentation done])

=head1 SUPPORT

You can email me, I can't promise response times.
If I start getting a lot of mail I'll start a list.

=head1 AUTHOR

  Michael Grubb
  mgrubb@cpan.org
  http://www.fifthvision.net  -- This is junk right now.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

