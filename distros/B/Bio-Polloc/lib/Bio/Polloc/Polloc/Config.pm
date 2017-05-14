=head1 NAME

Bio::Polloc::Polloc::Config - Handles .cfg files

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 DESCRIPTION

See the scripts folder (.bme files) for examples of the expected
syntaxis.

=cut

package Bio::Polloc::Polloc::Config;
use base qw(Bio::Polloc::Polloc::Root Bio::Polloc::Polloc::IO);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 GLOBALS

Global variables controling the behavior of the package

=over

=cut

our($CFGMAXDEPTH, $CFGCURDEPTH);

=item CFGMAXDEPTH

Maximum depth of variables replacement

=cut

$CFGMAXDEPTH = 7 unless defined $CFGMAXDEPTH;

=item CFGCURDEPTH

Current depth of replacement (internal var)

=back

=cut

$CFGCURDEPTH = 0;

=head1 APPENDIX

Methods provided by the package

=head2 new

=over

=item 

Initialization method.

=item Arguments

=over

=item -spaces I<arr of str>

A reference to an array of strings, each containing a namespace to be
parsed.

=item -noparse I<bool (int)>

If set to true, does not automatically parse the file on creation.  If so,
the L<parse> function must be manually called.

=back

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 parse

=over

=item 

Parses the configuration file.

=item Throws

L<Bio::Polloc::Polloc::IOException> on parsing error.

=back

=cut

sub parse {
   my($self,@args) = @_;

   $CFGCURDEPTH = 0;
   my $onspace = "";
   my @spaces = @{$self->spaces};
   $self->debug("The fine art of parsing (".$self->resource.")...");
   while(my $line = $self->_readline){
      $line = $self->_filter_line($line);
      next if $line =~ /^\s*$/;
      if($line =~ m/^\[\s*([\w\.]+)\s*\]$/){
         # [ space ]
	 $self->debug("[$onspace] Space: $line");
	 $onspace = $self->_parse_space($1);
      }elsif( !$self->_space_required($onspace) ){
         # Ignore space
	 $self->debug("[$onspace] Ignored: $line");
	 next;
      }elsif($line =~ m/^([\w\.]+)\s*=\s*(.*)$/){
	 $self->debug("[$onspace] Key-value pair: $line");
         # key = value
	 $self->_save(-space=>$onspace, -key=>$1, -value=>$2);
      }elsif($line =~ m/^([\w\.]+)(\s+(.*))?$/){
	 $self->debug("[$onspace] Token: $line");
         # token body || token
	 # Note that 'key = value' also fits this expresion because body
	 # is anything, but it has been already ruled out.
	 $self->_execute_token(-space=>$onspace, -token=>$1, -body=>$3);
      }else{
         $self->throw("Unable to parse configuration file ".$self->file,
	 		$line, "Bio::Polloc::Polloc::IOException");
      }
   }
   $self->close();
   $self->_reparse();
   $self->_execute_postparse();
}

=head2 spaces

=over

=item 

Gets/sets the spaces to be parsed.

=back

=cut

sub spaces {
   my $self = shift;
   $self->{'_spaces'} = ['.'] unless defined $self->{'_spaces'};
   while ( my $a = shift ) {
      for my $s (@{ ref($a) =~ /array/i ? $a : [$a] }){
         push @{$self->{'_spaces'}}, $self->_parse_space($s);
      }
   }
   return $self->{'_spaces'};
}

=head2 value

=over

=item 

Gets the value of a given key.

=item Arguments

=over

=item -key I<str>

The key (can contain namespace).

=item -space I<str>

The namespace.

=item -mandatory I<bool (int)>

If true, dies if not found.

=item -noalert I<bool (int)>

If true, does not alert if not found.

=back

=item Throws

L<Bio::Polloc::Polloc::Error> If not found and mandatory.

=back

=cut

sub value {
   my($self,@args) = @_;
   my($key, $space, $mandatory, $noalert) =
   	$self->_rearrange([qw(KEY SPACE MANDATORY NOALERT)],@args);
   return unless $key;
   $key = $self->_parse_key(-key=>$key, -space=>$space);
   my $alias = $self->alias($key);
   if($alias){
      $self->debug("Retrieving value by alias ($key -> $alias)");
      return $self->value($alias);
   }
   unless(defined $self->{'_data'}->{$key}){
      $self->throw("Unable to find a value for the key", $key) if $mandatory;
      $self->warn("Unable to find a value for the key", $key) unless $noalert;
   }
   return $self->{'_data'}->{$key};
}

=head2 all_keys

=over

=item 

Gets all the stored keys.

=item Arguments

=over

=item -space I<str>

The parent space.  By default C<.>.

=back

=item Returns

All the keys within the space (array of str).

=back

=cut

sub all_keys {
   my($self,@args) = @_;
   my($space) = $self->_rearrange([qw(SPACE)], @args);
   $space||= '.';
   $space = $self->_parse_space($space);
   return grep { /^$space/ } keys %{ $self->{'_data'} };
}

=head2 alias

=over

=item 

A key by alias.

=item Arguments

=over

=item -from I<str>

The B<from> key name.

=item -to I<str>

The B<to> key name.

=back

=item Throws

L<Bio::Polloc::Polloc::Error> if any of the two keys is empty.

=back

=cut

sub alias {
   my($self,@args) = @_;
   my($from,$to) = $self->_rearrange([qw(FROM TO)], @args);
   $self->{'_alias'} ||= {};

   return unless $from;
   my $k = $self->_parse_key($from);
   $k or $self->throw("Illegal virual key as alias", $from);
   if(defined $to){
      my $d = $self->_parse_key($to);
      $self->debug("Saving alias ($k -> $d)");
      $d or $self->throw("Illegal target key to create alias", $to);
      $self->{'_alias'}->{$k} = $d;
   }
   return $self->{'_alias'}->{$k};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _filter_line

=over

=item 

Removes comments from lines and lines with spaces only.

=back

=cut

sub _filter_line {
   my($self,$line) = @_;

   chomp($line);
   $line =~ s/^#.*//;
   $line =~ s/\s#.*//;
   $line =~ s/^\s+//;
   $line =~ s/\s+$//;

   return $line;
}

=head2 _save

=over

=item 

Saves a key/value pair.

=item Arguments

=over

=item -space I<str>

The namespace

=item -key I<str>

The name of the key (can contain the namespace before a dot (.) if not
explicitly provided).

=item -value I<str>

The value.

=back

=item Returns

The (uniform) key of the saved pair.  If array or list, the key and the value.

=back

=cut

sub _save {
   my($self,@args) = @_;
   my($space,$key,$value) = $self->_rearrange([qw(SPACE KEY VALUE)], @args);
   return unless $key;
   
   # Parse key
   $key = $self->_parse_key(-space=>$space, -key=>$key);
   
   # Parse value
   if( !$value ){
      $value = "";
   }elsif($value =~ m/^(true|false)$/i){
      $value = ("true" eq lc $value);
   }elsif($value =~ m/^[\d\.Ee+\-]+$/){
      $value += 0;
   }elsif($value =~ m/^'(.*)'$/){
      $value = $1;
      $value =~ s/\$\{/\$\\{/;
   }elsif($value =~ m/^"(.*)"$/ ){
      $value = $1;
      push @{$self->{'_reparse'}}, $key if $value =~ /\$\{[\w\.]+\}/;
   }else{
      $self->throw("Bad value on configuration file ".$self->resource,
      		$value, "Bio::Polloc::Polloc::IOException");
   }
   $self->{'_data'}->{$key} = $value;

   return wantarray ? ($key,$value) : $key;
}

=head2 _parse_space

=over

=item 

Parses (cleans) the name of a namespace.

=item Arguments

The namespace to parse.

=item Returns

The parsed (uniform) namespace.

=back

=cut

sub _parse_space {
   my($self, $space) = @_;
   return '.' unless defined $space;
   my $out = lc $space;
   $out = "." . $out unless $out =~ m/^\./;
   $self->throw("Invalid space name <$out>", $space) unless $out =~ m/^[\w\.]+(\.\*)?$/i;
   return $out;
}

=head2 _space_required

=over

=item 

Indicates whether a namespace is required.  I<I.e.>, if the user explicitly
requiested the space, any child or any parent.

=item Arguments

The namespace.

=item Returns

Boolean (int).

=back

=cut

sub _space_required {
   my($self,$space) = @_;
   $space = $self->_parse_space($space);
   # Top-level space
   
   for my $req_space ( @{ $self->spaces } ) {
      return $req_space if (
      		# Explicitly required space
      		($req_space eq $space) ||
		# Among children of a required space.* 
      		($req_space =~ m/^(.+)\.\*$/ &&
      			$space =~ m/^$1\.[^\.]+/) ||
		# Parent of some required space
		($space =~ m/^$req_space\..*/)
	);
   }
   return 0;
}

=head2 _execute_token

=over

=item 

Executes a token expected to map to a function.

=item Arguments 

=over

=item -token I<str>

The token (can contains namespace if not explicitly passed).

=item -space I<str>

The namespace of the token.

=item -body I<str>

A reference to an array containing the arguments to be passed to the
function.

=back

=back

=cut

sub _execute_token {
   my($self,@args) = @_;
   my ($token, $space, $body) = $self->_rearrange([qw(TOKEN SPACE BODY)], @args);
   $token = $self->_parse_key(-key=>$token, -space=>$space);
   $self->debug("Running $token with $body");
   defined  $self->_get_handle_function($token) or
      $self->throw("Any handle function for the called token", $token);
   my $hf = $self->_get_handle_function($token);
   ref($hf) =~ /HASH/i or
      $self->throw("Unexpected type of stored function", $hf);
   defined $hf->{'-obj'} && defined $hf->{'-fun'} or
      $self->throw("Incomplete function $token, imposible to complete call", $hf);
   eval {
      my $obj = $hf->{'-obj'};
      my $fun = $hf->{'-fun'};
      $obj->$fun($body, $hf->{'-defaults'});
   };
   if( $@ ){
      $self->throw("Error calling $token [$body]:\n$@", $hf);
   }
   return;
}

=head2 _execute_postparse

=over

=item 

Executes registered functions to be launched once parsing is finnished.

=back

=cut

sub _execute_postparse {
   my($self,@args) = @_;
   $self->debug("Running postparse functions");
   for my $fn ( @{$self->_postparse_functions} ){
      next unless defined $fn; # This should never happens
      ref($fn) =~ /HASH/i or $self->throw("Unexpected type of stored function", $fn);
      defined $fn->{'-obj'} && defined $fn->{'-fun'} or
         $self->throw("Incomplete function, imposible to complete call", $fn);
      eval {
         my $obj = $fn->{'-obj'};
	 my $fun = $fn->{'-fun'};
	 $obj->$fun($fn->{'-defaults'});
      };
      if( $@ ){
         $self->throw("Error calling lambda function (for postparse):\n$@", $fn);
      }
   }
   return;
}

=head2 _register_handle_function

=over

=item 

Register a handle function (for tokens).

=item Arguments

=over

=item -token I<str>

Token (can contain namespace).

=item -obj I<ref to obj>

Reference to the object *containing* the function.

=item -fun I<str>

Name of the function (note that this is the name of the
function within the object, not a reference to the function
itself).

=item -defaults I<ref to arr>

Default parameters to be passed to the function after the
body.

=item -space I<str>

Namespace of the token.

=back

=back

=cut

sub _register_handle_function {
   my($self,@args) = @_;
   my($token, $obj, $fun, $defaults, $space) =
   	$self->_rearrange([qw(TOKEN OBJ FUN DEFAULTS SPACE)], @args);
   $token = $self->_parse_key(-key=>$token, -space=>$space);
   my $hf = {-obj=>$obj, -fun=>$fun, -defaults=>$defaults};
   $self->_handle_functions;
   $self->{'_handle_functions'}->{$token} = $hf;
}

=head2 _register_postparse_function

=over

=item 

Registers a function to be launched once parsing is complete.

=item Arguments

=over

=item -obj I<ref to obj>

The object containing the function.

=item -fun I<str>

The name of the function within the object.

=item -defaults I<ref to arr>

The parameters to be passed to the function.

=back

=back

=cut

sub _register_postparse_function {
   my($self,@args) = @_;
   my($obj, $fun, $defaults) = $self->_rearrange([qw(OBJ FUN DEFAULTS)], @args);
   my $hf = {-obj=>$obj, -fun=>$fun, -defaults=>$defaults};
   $self->_postparse_functions;
   push @{$self->{'_postparse_functions'}}, $hf;
}

=head2 _handle_functions

=over

=item 

Gets the collection of functions to handle tokens.

=back

=cut

sub _handle_functions {
   my($self,@args) = @_;
   $self->{'_handle_functions'} = {} unless defined $self->{'_handle_functions'};
   return $self->{'_handle_functions'};
}

=head2 _postparse_functions

=over

=item 

Gets the collection of functions to be launched after parsing.

=back

=cut

sub _postparse_functions {
   my($self,@args) = @_;
   $self->{'_postparse_functions'} = [] unless defined $self->{'_postparse_functions'};
   return $self->{'_postparse_functions'};
}

=head2 _get_handle_function

=over

=item 

Gets the handle function for the given token.

=item Arguments

=over

=item -token I<str>

The token.

=back

=back

=cut

sub _get_handle_function {
   my($self,@args) = @_;
   my($token) = $self->_rearrange([qw(TOKEN)], @args);
   $self->_handle_functions;
   return $self->{'_handle_functions'}->{$token};
}

=head2 _reparse

=over

=item 

Parses recursively all values until no references to other vars last or
the maximum depth is reached, whatever happens first.

=back

=cut

sub _reparse {
   my($self,@args) = @_;
   $self->{'_reparse'} = [] unless defined $self->{'_reparse'};
   my @reparse = @{$self->{'_reparse'}};
   $self->{'_reparse'} = [];
   return unless $#reparse>=0;
   if($CFGCURDEPTH++ >= $CFGMAXDEPTH){
      $self->warn("Maximum depth reached, some unparsed variables left");
      return;
   }
   for my $key (@reparse){
      next unless $key;
      my $v = $self->value($key);
      while($v =~ m/\$\{([\w\.]+)\}/){
      	 my $k2 = $1;
	 my $v2 = $self->value($k2);
      	 $v =~ s/\$\{$k2\}/$v2/g;
      }
      $self->_save(-key=>$key, -value=>"\"$v\"");
   }
   
   $self->_reparse(@args);
}

=head2 _parse_key

=over

=item 

Parses a key and returns its uniform name.

=item Arguments

=over

=item -key I<str>

The key name (can contain namespace if not explicitly set).

=item -space I<str>

The namespace.

=back

=back

=cut

sub _parse_key {
   my($self,@args) = @_;
   my($key,$space) = $self->_rearrange([qw(KEY SPACE)], @args);
   $key or $self->throw("Got an empty key to parse, illegal action", $key,
   		"Bio::Polloc::Polloc::IOException");
   $key = lc $key;
   $space = $self->_parse_space($space);
   $key = $space . "." . $key if $space && $key !~ /^\./;
   $key =~ s/\.\./\./g;
   $key =~ s/\.\./\./g;
   $self->throw("Bad key or token on configuration file ".$self->resource, $key,
   		"Bio::Polloc::Polloc::IOException")
   		unless $key=~m/^[\w\.]+$/;
   return $key;
}

=head2 _key_alias

=over

=item 

Creates an alias for a key based on a string input.  See L<alias>.

=item Arguments

A string containing the name of the B<from> key, one or more spaces and the name
of the B<to> string.  Can contain surrounding spaces.

=item Throws

L<Bio::Polloc::Polloc::Error> if empty string or not properly formatted.

=back

=cut

sub _key_alias {
   my($self,$body,@args) = @_;
   $body or $self->throw("Empty body for alias", $body);
   $body =~ s/^\s*//;
   $body =~ s/\s*$//;
   my($from,$to) = split /\s+/, $body;
   $from or $self->throw("Any virtual key on alias", $body);
   $to or $self->throw("Any target key on alias", $body);
   $self->alias($from, $to);
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->_initialize_io(@args);
   my($spaces, $noparse) = $self->_rearrange([qw(SPACES NOPARSE)], @args);
   $self->{'_data'} = {};
   $self->spaces($spaces);
   $self->_register_handle_function(
   		-obj=>$self,
		-fun=>"_key_alias",
		-token=>".alias"
   	);
   $self->parse(@args) unless $noparse;
}


1;
