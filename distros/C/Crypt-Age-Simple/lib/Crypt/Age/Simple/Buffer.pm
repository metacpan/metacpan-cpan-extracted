package Crypt::Age::Simple::Buffer;
use v5.24;
use Moo;
use English qw< -no_match_vars >;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;

sub trim ($buffers, $offset) {
   while ($offset > 0 && $buffers->@*) {
      my $len = length($buffers->[0]->$*);
      last if $offset < $len;
      shift($buffers->@*);
      $offset -= $len;
   }
   ouch 400, 'invalid offset: more than data'
      if ($offset > 0) && ($buffers->@* == 0);
   return $offset;
}

use namespace::clean;

has _offset  => (is => 'rw');

has _buffers => (is => 'ro');  # we will be manipulating the inside, anyway

around BUILDARGS => sub ($orig, $class, @args) {
   my %args = @args == 1 ? $args[0]->%* : @args;

   # buffers... get rid of empty stuff
   my $aref = ref($args{buffers}) eq 'ARRAY' ? $args{buffers}
      : ref($args{buffers}) eq 'SCALAR' ? [ $args{buffers} ]
      : [ defined($args{buffers}) ? \$args{buffers} : () ];
   my $buffers = [ grep { defined($_) && length($$_ // '') } $aref->@* ];

   my $offset = $args{offset} || 0;
   ouch 400, 'invalid offset' if $offset !~ m{\A (?: 0 | [1-9]\d*) \z}mxs;

   $offset = trim($buffers, $offset);

   return $class->$orig(_buffers => $buffers, _offset => $offset);
};

sub has_data ($self)       { return scalar($self->_buffers->@*) > 0 }

sub available_chunks ($self) { return scalar($self->_buffers->@*) }

sub available_bytes ($self) { 
   my $bo = $self->_buffers;
   my $n = $bo->@*;
   return 0 if $n == 0;

   my $size = 0 - $self->_offset;
   $size += length($$_) for $bo->@*;
   return $size;
}

sub put ($self, $input) {
   my $aref = ref($input) eq 'ARRAY' ? $input
      : ref($input) eq 'SCALAR' ? [ $input ]
      : (! ref($input)) ? [ \$input ]
      : ouch 400, 'cannot handle inputs as ' . ref($input);
   push($self->_buffers->@*, $aref->@*);
   return $self;
}

sub give_back ($self, $input, $input_offset = 0) {
   my $aref = ref($input) eq 'ARRAY' ? $input
      : ref($input) eq 'SCALAR' ? [ $input ]
      : ref($input) ? ouch 400, 'cannot handle inputs as ' . ref($input)
      : length($input // '') == 0 ? [] : [ \$input ];
   my @parts = $aref->@* or return $self;
   $input_offset = trim(\@parts, $input_offset);

   my $bo = $self->_buffers;
   my $offset = $self->_offset;
   if ($offset > 0) {
      my $n_copy_existing = length($bo->[0]->$*) - $offset;

      my @popped;
      my $n = 0;
      while ($offset > 0 && @parts > 0) {
         my $len = length($parts[-1]);
         $len -= $input_offset if @parts == 1;
         if ($len <= $offset) { # just rewind the offset
            $offset -= $len;
            $n += $len;
            push @popped, pop(@parts);
         }
         else { # we have to decide...
            my $n_copy_incoming = $len - $offset;
            if ($n_copy_incoming <= $n_copy_existing) {
               my $part;
               my $pref = pop(@parts);
               if (@parts == 0) { # first part...
                  $part = substr($$pref, $input_offset, $n_copy_incoming);
                  $input_offset = 0;
               }
               else {
                  my $part = substr($$pref, 0, $n_copy_incoming);
               }
               push @parts, \$part;
            }
            else {
               my $pref = shift($bo->@*);
               my $part = substr($$pref, $offset);
               push @parts, \$part;
            }
            # whatever happened, offset is 0 now
            $offset = 0;
         }
      }
   }

   return $self if @parts == 0;
   ouch 500, 'offset > 0 is unacceptable at this point' if $offset > 0;
   unshift($bo->@*, @parts);
   $self->_offset($input_offset);
}

sub drop_bytes ($self, $n) {
   $self->_offset(trim($self->_buffers, $self->_offset + $n));
   return $self;
}

sub get_bytes_exactly ($self, $n) {
   ouch 400, "cannot get exactly: $n" if $n > $self->available_bytes;
   return $self->get_bytes($n);
}

sub get_bytes ($self, $n = undef) {
   my $retval = '';
   $n //= $self->available_bytes;
   my $bo = $self->_buffers;
   my $offset = $self->_offset;

   # quick interface: we want exactly the full first chunk. This will
   # speed up things if data is pumped in the "right" way
   return shift($bo->@*)
      if $offset == 0 && $bo->@* > 0 && $n == length($bo->[0]->$*);

   while ($n > 0 && $bo->@* > 0) {
      my $available = length($bo->[0]->$*) - $offset;
      if ($n < $available) {
         $retval .= substr($bo->[0]->$*, $offset, $n);
         $offset += $n;
         $n = 0; # got what I came for
      }
      else {  # get the whole chunk
         my $chunk = shift($bo->@*);
         $retval .= ($offset > 0) ? substr($$chunk, $offset) : $$chunk;
         $offset = 0; # reset the offset to the start of the next chunk
         $n -= $available;
      }
   }
   $self->_offset($offset);
   return \$retval;
}

sub get_parts ($self, $n = undef) {
   my $bo = $self->_buffers;
   $n //= $bo->@*;
   $n = $bo->@* if $n > $bo->@*;
   my @retval = splice($bo->@*, 0, $n);
   if (my $offset = $self->_offset) { # offset the first item
      my $part = substr(shift(@retval)->$*, $offset);
      unshift(@retval, \$part);
      $self->_offset(0);  # reset the offset
   }
   return wantarray() ? @retval : \@retval;
}

sub index_of ($self, $substr) {
   my $bo = $self->_buffers;
   my $offset = $self->_offset;
   my $i = 0;
   for my $part ($bo->@*) {
      my $j = index($$part, $substr, $offset);
      return $i + $j if $j >= 0;
         
      # prepare for next iteration, if any
      $i += length($$part);
      $offset = 0;
   }

   return -1;
}

1;
