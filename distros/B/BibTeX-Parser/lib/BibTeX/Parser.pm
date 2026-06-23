package BibTeX::Parser;
{
    $BibTeX::Parser::VERSION = '1.94';
}
# ABSTRACT: A pure perl BibTeX parser
use warnings;
use strict;

require BibTeX::Parser::Entry; # mutual dependency, so use instead of require


my $re_namechar = qr/[a-zA-Z0-9\!\$\&\*\+\-\.\/\:\;\<\>\?\[\]\^\_\`\|\']/o;
my $re_name     = qr/$re_namechar+/o;


sub new {
    my ( $class, $fh, $opts ) = @_;

    return bless {
        fh      => $fh,
        opts    => $opts || {},
        strings => {
            jan => "January",
            feb => "February",
            mar => "March",
            apr => "April",
            may => "May",
            jun => "June",
            jul => "July",
            aug => "August",
            sep => "September",
            oct => "October",
            nov => "November",
            dec => "December",
	    "j-tugboat" => "TUGboat", # missing definition is irritating
        },
        line   => -1,
        buffer => "",
	entries => {}
    }, $class;
}

sub read {
    my $self = shift;
    if (!exists $self->{opts}->{errorlevel}) {
	$self->{opts}->{errorlevel} = 'warn';
    }
    while (my $entry=$self->next) {
	if ($entry->parse_ok) {
	    $self->{entries}->{$entry->key()} = $entry;
	} else {
	    if ($self->{opts}->{errorlevel} eq 'warn') {
		warn "BibTeX Parser: Skipping entry in line $."
	    } elsif ($self->{opts}->{errorlevel} eq 'error') {
		exit("BibTeX Parser: Error in line $.")
	    }
	}
    }
}

sub n {
    my $self = shift;
    return(scalar keys %{$self->{entries}});
}

sub entrykeys {
    my $self = shift;
    my @result = keys %{$self->{entries}};
    return(\@result);
}

sub has {
    my $self = shift;
    my $key = shift;
    return(exists($self->{entries}->{$key}));
}

sub entry {
    my $self = shift;
    my $key = shift;
    return($self->{entries}->{$key});
}

sub _slurp_close_bracket;

sub _parse_next {
    my $self = shift;

    while (1) {    # loop until regular entry is finished
        return 0 if $self->{fh}->eof;
        local $_ = $self->{buffer};

        until (/@/m) {
            my $line = $self->{fh}->getline;
            return 0 unless defined $line;
            $line =~ s/^%.*$//;
            $_ .= $line;
        }

        my $current_entry = new BibTeX::Parser::Entry;
        if (/@($re_name)/cgo) {
	    my $type = uc $1;
            $current_entry->type( $type );
            my $start_pos = pos($_) - length($type) - 1;

            # read rest of entry (matches braces)
            my $bracelevel = 0;
            $bracelevel += tr/\{/\{/;    #count braces
            $bracelevel -= tr/\}/\}/;
            while ( $bracelevel != 0 ) {
                my $position = pos($_);
                my $line     = $self->{fh}->getline;
				last unless defined $line;
                $bracelevel =
                  $bracelevel + ( $line =~ tr/\{/\{/ ) - ( $line =~ tr/\}/\}/ );
                $_ .= $line;
                pos($_) = $position;
            }

            # Remember text before the entry
            my $pre = substr($_, 0, $start_pos-1);
	    if ($start_pos == 0) {
		$pre = '';
	    }
            $current_entry->pre($pre);


            # Remember raw bibtex code
            my $raw = substr($_, $start_pos);
            $raw =~ s/^\s+//;
            $raw =~ s/\s+$//;
            $current_entry->raw_bibtex($raw);

            my $pos = pos $_;
            tr/\n/ /;
            pos($_) = $pos;

            if ( $type eq "STRING" ) {
                if (/\G\{\s*($re_name)\s*=\s*/cgo) {
                    my $key   = lc($1);
                    my $value = _parse_string( $self->{strings},
                                       exists $self->{opts}->{"no-warn-ack"} );
                    # If redefining to the same value, don't worry.
                    # If redefining j-tugboat (predefined above), don't worry,
                    #   people use \TUB vs. "TUGboat" arbitrarily.
                    my $old_value = $self->{strings}->{$key};
                    if ($key ne "j-tugboat"
                        && defined $old_value && $old_value ne $value) {
                        warn("Redefining string $key ",
                             "(oldvalue=$old_value, newvalue=$value");
                    }
                    $self->{strings}->{$key} = $value;
                    /\G[\s\n]*\}/cg;
                } else {
                    $current_entry->error("Malformed string! ($raw)");
                    return $current_entry;
                }
            } elsif ( $type eq "COMMENT" or $type eq "PREAMBLE" ) {
                /\G\{./cgo;
                _slurp_close_bracket;
            } else {    # normal entry
                $current_entry->parse_ok(1);

				# parse key
                if (/\G\s*\{(?:\s*($re_name)\s*,[\s\n]*|\s+\r?\s*)/cgo) {
                    $current_entry->key($1);

					# fields
                    while (/\G[\s\n]*($re_name)[\s\n]*=[\s\n]*/cgo) {
                        $current_entry->field(
                              $1 => _parse_string( $self->{strings}, 
                                     exists $self->{opts}->{"no-warn-ack"} ) );
                        my $idx = index( $_, ',', pos($_) );
                        pos($_) = $idx + 1 if $idx > 0;
                    }

                    return $current_entry;

                } else {

                    $current_entry->error("Malformed entry (key contains invalid characters) at " . substr($_, pos($_) || 0, 20)  . ", ignoring");
                    _slurp_close_bracket;
					return $current_entry;
                }
            }

            $self->{buffer} = substr $_, pos($_);

        } else {
            $current_entry->error("Did not find type at " . substr($_, pos($_) || 0, 20)); 
			return $current_entry;
        }

    }
}


sub next {
    my $self = shift;

    return $self->_parse_next;
}

# slurp everything till the next closing brace. Handles
# nested brackets
sub _slurp_close_bracket {
    my $bracelevel = 0;
  BRACE: {
        /\G[^\}]*\{/cg && do { $bracelevel++; redo BRACE };
        /\G[^\{]*\}/cg
          && do {
            if ( $bracelevel > 0 ) {
                $bracelevel--;
                redo BRACE;
            } else {
                return;
            }
          }
    }
}

# parse bibtex string in $_ and return. A BibTeX string is either enclosed
# in double quotes '""' or matching braces '{}'. The braced form may contain
# nested braces.
# 
# Second argument NO_WARN_ACK says whether to emit the warning
# "Using undefined string" if the name of the undefined string starts
# with "ack-". The default is to warn. The TUGboat config file
# ltx2crossrefxml-tugboat.cfg sets this.
# 
# It is an unfortunate fact that people routinely copy bib entries
# without copying the "ack-nhfb" or other "ack-..." @string definitions
# in Nelson Beebe's bibliography files, resulting in this warning. It is
# too irritating to have to define them (they are never used), and also
# too irritating to have to see the many warnings on every run.
# 
# Similarly for j-TUGboat, which we predefine in the new() fn above.
#
sub _parse_string {
    my ($strings_ref, $no_warn_ack) = @_;
    $no_warn_ack ||= 0;

    my $value = "";

  PART: {
        if (/\G(\d+)/cg) {
            $value .= $1;
        } elsif (/\G($re_name)/cgo) {
            my $key = lc($1);
            if (! defined $strings_ref->{lc($1)}) {
                #debug_hash("looking up $key for $1", $strings_ref);
                warn("Using undefined string $1 (", lc($1), ") in: $_")
                  unless $no_warn_ack && $1 =~ /^ack-/;
            }
            $value .= $strings_ref->{$1} || "";
        } elsif (/\G"(([^"\\]*(\\.)*[^\\"]*)*)"/cgs)
        {    # quoted string with embedded escapes
            $value .= $1;
        } else {
            my $part = _extract_bracketed( $_ );
            $value .= substr $part, 1, length($part) - 2;    # strip quotes
        }

        if (/\G\s*#\s*/cg) {    # string concatenation by #
            redo PART;
        }
    }
    $value =~ s/[\s\n]+/ /g;
    return $value;
}

sub _extract_bracketed
{
	for($_[0]) # alias to $_
	{
		/\G\s+/cg;
		my $start = pos($_);
		my $depth = 0;
		while(1)
		{
			/\G\\./cg && next;
			/\G\{/cg && (++$depth, next);
			/\G\}/cg && (--$depth > 0 ? next : last);
			/\G([^\\\{\}]+)/cg && next; 
			last; # end of string
		}
		return substr($_, $start, pos($_)-$start);
	}
}

# Split the $string using $pattern as a delimiter with
# each part having balanced braces (so "{$pattern}"
# does NOT split).
# Return empty list if unmatched braces

sub _split_braced_string {
    my $string = shift;
    my $pattern = shift;
    my @tokens;
    return () if  $string eq '';
    my $buffer;
    while (!defined pos $string || pos $string < length $string) {
	if ( $string =~ /\G(.*?)(\{|$pattern)/cgi ) {
	    my $match = $1;
	    if ( $2 =~ /$pattern/i ) {
		$buffer .= $match;
		push @tokens, $buffer;
		$buffer = "";
	    } elsif ( $2 =~ /\{/ ) {
		$buffer .= $match . "{";
		my $numbraces=1;
		while ($numbraces !=0 && pos $string < length $string) {
		    my $symbol = substr($string, pos $string, 1);
		    $buffer .= $symbol;
		    if ($symbol eq '{') {
			$numbraces ++;
		    } elsif ($symbol eq '}') {
			$numbraces --;
		    }
		    pos($string) ++;
		}
		if ($numbraces != 0) {
		    return ();
		}
	    } else {
		$buffer .= $match;
	    }
	} else {
	    $buffer .= substr $string, (pos $string || 0);
	    last;
	}
    }
    push @tokens, $buffer if $buffer;
    return @tokens;
}


#
sub debug_hash {
  my ($label) = shift;
  my (%hash) = (ref $_[0] && $_[0] =~ /.*HASH.*/) ? %{$_[0]} : @_;

  my $str = "$label: {";
  my @items = ();
  for my $key (sort keys %hash) {
    my $val = $hash{$key};
    $key =~ s/\n/\\n/g;
    $val =~ s/\n/\\n/g;
    push (@items, "$key:$val");
  }
  $str .= join (",", @items);
  $str .= "}";

  warn ($str);
}

#
sub debug_list {
  my ($label) = shift;
  my (@list) = (ref $_[0] && $_[0] =~ /.*ARRAY.*/) ? @{$_[0]} : @_;

  my $str = "$label [" . join (",", @list) . "]";
  warn $str;
}


# Return string representation of call stack for debugging.
# 
sub backtrace {
  my $ret = "";

  my ($line, $subr);
  my $stackframe = 1;  # skip ourselves
  while ((undef,undef,$line,$subr) = caller ($stackframe)) {
    $ret .= " -> $subr.$line";
    $stackframe++;
  }

  return $ret;
}


1;    # End of BibTeX::Parser


__END__
=pod

=head1 NAME

BibTeX::Parser - A pure perl BibTeX parser


=head1 SYNOPSIS

Parses BibTeX files.

    use BibTeX::Parser;
	use IO::File;

    my $fh = IO::File->new("filename");

    # Create parser object ...
    my $parser = BibTeX::Parser->new($fh, $opts);
    
    # ... and either iterate over entries
    while (my $entry = $parser->next ) {
	    if ($entry->parse_ok) {
		    my $type    = $entry->type;
		    my $title   = $entry->field("title");

		    my @authors = $entry->author;
		    # or:
		    my @editors = $entry->editor;
		    
		    foreach my $author (@authors) {
			    print $author->first . " "
			    	. $author->von . " "
				. $author->last . ", "
				. $author->jr;
		    }
	    } else {
		    warn "Error parsing file: " . $entry->error;
	    }
    }

   # ... or read all entries at once
   $parser->read();
   my $num_entries = $parser->n();
   my $entrykeys = $parser->entrykeys();
   foreach my $key (@{$entrykeys}) {
      my $entry = $parser->entry($key);
      ...
   }
   if ($parser->has{'thekey') {
     $theentry = $parser->entry('thekey');
   }

=head1 DESCRIPTION

  There are two interfaces for BiBTeX::Parser: the serial one and
  the caching one.  The serial interface can be used for very large
  files.  It reads entries one by one, and outputs them using $parser->next()
  function.  In other cases you might be better off with the caching
  interface.  It reads all the entries at once, and can output the
  list of keys or the entry with the given key.

=head1 FUNCTIONS

=head2 new

Creates new parser object. 

Parameters:

	* fh: A filehandle

        * opts: a refernce to the hash of options.  Among other
          options is 'errorlevel', used in the caching interface when
          processing a non-parseable entry.  Can be 'warn' (the
          default), 'erorr', or 'ignore'.  Note that in serial
          interface the error processing is the responsibility of the
          user.

=head2 next

Returns the next parsed entry or undef.  Cannot be combined with
the L<read> interface described below.

=head2 read

Read all the entries from the filehandle in the internal cache.  




=head2 n

Returns the number of entries after L<read> function has been called

=head2 entrykeys

Returns the array of keys after L<read> function has been called

=head2 entry

Returns an entry with the given key after L<read> function has been called

Parameters:

    * key: the key

=head2 has

Returns true if the cached file has the given entry

Parameters:

    * key: the key




=head1 NOTES

The fields C<author> and C<editor> are canonicalized, see
L<BibTeX::Parser::Author>.


=head1 SEE ALSO

=over 4

=item

L<BibTeX::Parser::Entry>

=item

L<BibTeX::Parser::Author>

=back

=head1 VERSION

version 1.94

=head1 AUTHOR

Gerhard Gossen <gerhard.gossen@googlemail.com> and
Boris Veytsman <boris@varphi.com> and
Karl Berry <karl@freefriends.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2026 Gerhard Gossen, Boris Veytsman, Karl Berry

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
