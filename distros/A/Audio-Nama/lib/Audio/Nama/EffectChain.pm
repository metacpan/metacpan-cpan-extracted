# ------------- Effect-Chain and -Profile routines --------
# Effect Chains
#
# we have two type of effect chains
# + global effect chains - usually user defined, available to all projects
# + system generated effect chains, per project

{
package Audio::Nama::EffectChain;
use v5.36;
use Data::Dumper::Concise;
use Carp;
use Exporter qw(import);
use Storable qw(dclone);
use Audio::Nama::Effect  qw(fxn append_effect);
use Audio::Nama::Log qw(logpkg logsub);
use Audio::Nama::Assign qw(json_out);

use Audio::Nama::Globals qw($fx_cache %tn $fx);

our $AUTOLOAD;
our $VERSION = 0.001;
no warnings qw(uninitialized);
our @ISA;
our ($n, %by_index, @attributes, %is_attribute);
use Audio::Nama::Object qw( 

		n					
		ops_list			
        ops_data			
		inserts_data		
		fade_data			
		region				
		attrib 				
		class				
        is_mixing           
		source_tag 			

		);
@attributes = qw(

  		name				
  		project				
  		global				
  		profile				
  		user				
  		system				
  		track_name			
  		track_version_result 	
  		track_version_original 	
  		track_target_original 
  		insert				
  		track_cache			
 		track_target		
  		bypass				
  		id					

	) ;


%is_attribute = map{ $_ => 1 } @attributes;
initialize();

## sugar for accessing individual effect attributes
## similar sugar is used for effects. 

sub is_controller {
	my ($self, $id) = @_;
	$self->{ops_data}->{$id}->{belongs_to}
}
sub parent_id : lvalue {
	my ($self, $id) = @_;
	$self->{ops_data}->{$id}->{belongs_to}
}
sub type {
	my ($self, $id) = @_;
	$self->{ops_data}->{$id}->{type}
}
sub params {
	my ($self, $id) = @_;
	$self->{ops_data}->{$id}->{params}
}

sub initialize {
	$n = 0;
	%by_index = ();	
}
sub new_index { $n++; $by_index{$n} ?  new_index() : $n }
sub new {
	# arguments: ops_list, ops_data, inserts_data
	# ops_list => [id1, id2, id3,...];
	my $class = shift;	
	my %vals = @_;

	# we need to so some preparation if we are creating
	# an effect chain for the first time (as opposed
	# to restoring a serialized effect chain)

	if (! $vals{n} ) {

		# move secondary attributes to $self->{attrib}->{...}
		move_attributes(\%vals);

		$vals{n} = new_index();
		$vals{inserts_data} ||= [];
		$vals{ops_list} 	||= [];
		$vals{ops_data} 	||= {};
		$vals{fade_data}    ||= [];
		my @und = grep{ ! $_is_field{$_} } keys %vals;
		croak "undeclared field @und in: @_" if @und;
		croak "must have exactly one of 'global' or 'project' fields defined" 
			unless ($vals{attrib}{global} xor $vals{attrib}{project});

		logpkg(__FILE__,__LINE__,'debug','constructor arguments ', sub{ json_out(\%vals) });

		my $ops_data = {};
		# ops data is taken preferentially 
		# from ops_data argument, with fallback
		# to existing effects
		
		# in both cases, we clone the data structures
		# to ensure we don't damage the original
		
		for (@{$vals{ops_list}}){ 	

			if ( $vals{ops_data}->{$_} )
											
			{ 	
				$ops_data->{$_} 		  = dclone($vals{ops_data}->{$_});
			}
			else
			{
				my $filtered_op_data = dclone( fxn($_)->as_hash );# copy
				my @unwanted_keys = qw( chain bypassed name surname display);
				delete $filtered_op_data->{$_} for @unwanted_keys;
				$ops_data->{$_} = $filtered_op_data;
			}

		} ;
		

		$vals{ops_data} = $ops_data;

		if( scalar @{$vals{inserts_data}})
		{

			# rewrite inserts to store what we need:
			# 1. for general-purpose effects chain use
			# 2. for track caching use
		
			
			$vals{inserts_data} = 
			[ 
				map
				{ 
					logpkg(__FILE__,__LINE__,'debug',"insert: ", sub{Dumper $_});
					my @wet_ops = @{$tn{$_->wet_name}->ops};
					my @dry_ops = @{$tn{$_->dry_name}->ops};
					my $wet_effect_chain = Audio::Nama::EffectChain->new(
						project => 1,
						insert	=> 1,
						ops_list => \@wet_ops,
					);
					my $dry_effect_chain = Audio::Nama::EffectChain->new(
						project => 1,
						insert => 1,
						ops_list => \@dry_ops,
					);
					my $hash = dclone($_->as_hash);

					$hash->{wet_effect_chain} = $wet_effect_chain->n;
					$hash->{dry_effect_chain} = $dry_effect_chain->n;

					map{ delete $hash->{$_} } qw(n dry_vol wet_vol track);	

					# Reasons for deleting insert attributes
					
					# n: we'll get a new index when we re-apply
					# dry_vol, wet_vol: will never be re-allocated
					#    so why not reuse them?
					#    except for general purpose we'd like to
					#    re-allocate
					# track: we already know the track from
					#    the parent effect chain

					# What is left:
					# 
					# 	class
					#	wetness
					#	send_type
					#	send_id
					#	return_type
					#	return_id
					#	wet_effect_chain => ec_index,
					#   dry_effect_chain => ec_index,
					
					$hash
				} @{$vals{inserts_data}}
			];
		}

		#say Audio::Nama::json_out($vals{inserts_data}) if $vals{inserts_data};
	}
	my $object = bless { %vals }, $class;
	$by_index{$vals{n}} = $object;
	logpkg(__FILE__,__LINE__,'debug',sub{$object->dump});
	$object;
}
sub AUTOLOAD {
	my $self = shift;
	my ($call) = $AUTOLOAD =~ /([^:]+)$/;
	return $self->{attrib}->{$call} if exists $self->{attrib}->{$call}
		or $is_attribute{$call};
	croak "Autoload fell through. Object type: ", (ref $self), ", illegal method call: $call\n";
}

### apply effect chain to the specified track

sub add_ops {
	my($self, $track, $ec_args) = @_;

	# Higher priority: track argument 
	# Lower priority:  effect chain's own track name attribute
	$track ||= $tn{$self->track_name} if $tn{$self->track_name};
	

	# make sure surname is unique
	
	my ($new_surname, $existing) = $track->unique_surname($ec_args->{surname});
	if ( $new_surname ne $ec_args->{surname})
	{
		Audio::Nama::pager_newline(
			"track ".
			$track->name.qq(: other effects with surname "$ec_args->{surname}" found,),
			qq(using "$new_surname". Others are: $existing.));
		$ec_args->{surname} = $new_surname;
	}

	
	logpkg(__FILE__,__LINE__,'debug',$track->name,
			qq(: adding effect chain ), $self->name, Dumper $self
		 
		);

	# Exclude restoring vol/pan for track_caching.
	# (This conditional is a hack that would be better 
	# implemented by subclassing EffectChain 
	# for cache/uncache)
	
	my @ops_list;
	my @added;
	if( $self->track_cache ){
		@ops_list = grep{ $_ ne $track->vol and $_ ne $track->pan }
								@{$self->ops_list}
	} else {
		@ops_list = @{$self->ops_list};
	}
	for (@ops_list)
	{	
		my $args = 
		{
			chain  		=> $track->n,
			type   		=> $self->type($_),
			params 		=> $self->params($_),
			parent		=> $self->parent_id($_),
		};

		
		# drop the ID if it is already used
		$args->{id} = $_ unless fxn($_);

		logpkg(__FILE__,__LINE__,'debug',"args ", json_out($args));

		$args->{surname} = $ec_args->{surname} if $ec_args->{surname};

		my $FX = append_effect($args)->[0];
		push @added, $FX;
		my $new_id = $FX->id;
		
		# the effect ID may be new, or it may be previously 
		# assigned ID, 
		# whatever value is supplied is guaranteed
		# to be unique; not to collide with any other effect
		
		logpkg(__FILE__,__LINE__,'debug',"new id: $new_id");
		my $orig_id = $_;
		if ( $new_id ne $orig_id)
		# re-write all controllers to belong to new id
		{
			map{ $self->parent_id($_) =~ s/^$orig_id$/$new_id/  } @{$self->ops_list}
		}
		
	}
}
sub add_inserts {
	my ($self, $track) = @_;
	map 
	{
		my $insert_data = dclone($_); # copy so safe to modify 
		#say "found insert data:\n",Audio::Nama::json_out($insert_data);

		# get effect chain indices for wet/dry arms
		
		my $wet_effect_chain = delete $insert_data->{wet_effect_chain};
		my $dry_effect_chain = delete $insert_data->{dry_effect_chain};
		my $class 			 = delete $insert_data->{class};

		$insert_data->{track} = $track->name;
		my $insert = $class->new(%$insert_data);
		#$Audio::Nama::by_index{$wet_effect_chain}->add($insert->wet_name, $tn{$insert->wet_name}->vol)
		#$Audio::Nama::by_index{$dry_effect_chain}->add($insert->dry_name, $tn{$insert->dry_name}->vol)
	} @{$self->inserts_data};
}
sub add_region {
	my ($self, $track) = @_;
	# there is also a check in uncache track
	Audio::Nama::throw($track->name.": track already has region definition\n",
		"failed to apply region @$self->{region}\n"), return
		if $track->is_region;
	$track->set(region_start => $self->{region}->[0],
				region_end	 => $self->{region}->[1]);
}

sub add {
	my ($self, $track) = @_;
	# TODO stop_do_start should take place at this level
	# possibly reconfiguring engine
	my $args = {};
	$args->{surname} = $self->name if $self->name;
	$self->add_ops($track, $args);
	#$track->{ops} = dclone($self->ops_list);
	$self->add_inserts($track);
	$self->add_region($track) if $self->region;
	$self->add_fades($track) if $self->fade_data;
	1 # succeeded 

}

sub add_fades {
	my ($self, $track) = @_;
	map{ 
		my %h = %$_; 
		my $fade = Audio::Nama::Fade->new( %h, track => $track->name ) ;
	} @{ $self->{fade_data} }
}
sub destroy {
	my $self = shift;
	delete $by_index{$self->n};
}

#### class routines
	
sub find { 

# find(): search for an effect chain by attributes
#
# Returns EffectChain objects in list context,
# number of matches in scalar context.

	my %args = @_;
	my $unique = delete $args{unique};

	# first check for a specified index that matches
	# an existing chain
	
	return $by_index{$args{n}} if $args{n};

	# otherwise all specified fields must match
	
	my @found = grep
		{ 	my $fx_chain = $_;
			
			# check if any specified fields *don't* match
			
			my @non_matches = grep 
			{ 

				! ($fx_chain->{attrib}->{$_} eq $args{$_}) 

				#! ($_ ne 'version' and $args{$_} eq 1 and $fx_chain->$_)

			} keys %args;

			# if no non-matches, then all have matched, 
			# and we return true

			! scalar @non_matches
		
       } values %by_index;

	warn("unique chain requested but multiple chains found. Skipping.\n"),
		return if $unique and @found > 1;

	if( wantarray() ){ $unique ? pop @found : sort{ $a->n cmp $b->n } @found  }
	else { scalar @found }
}

sub summary {
	my $self = shift;
	my @output;
	push @output, "  name: ".$self->name if $self->name;
	push @output, "  track name: ".$self->track_name if $self->track_name;
	push @output,	
	map{ 
		my $i = Audio::Nama::effect_index( $self->{ops_data}->{$_}->{type} ); 
		my $name = "    ". $fx_cache->{registry}->[$i]->{name};
	} @{$_->ops_list};
	map{ $_,"\n"} @output;
}

sub move_attributes {
	my $ec_hash = shift;
	map { $ec_hash->{attrib}->{$_} = delete $ec_hash->{$_}  } 
	grep{ $ec_hash->{$_} }
	@attributes;
}

sub DESTROY {}

}
{	
####  Effect-chain and -profile routines

package Audio::Nama;
sub add_effect_chain {
	my ($name, $track) = @_;
	my ($ec) = Audio::Nama::EffectChain::find(
		unique => 1, 
		user   => 1, 
		name   => $name,
	);
	if( $ec ){ $ec->add($Audio::Nama::this_track) }
	else { Audio::Nama::throw("$name: effect chain not found") }
	1;
}
sub new_effect_profile {
	logsub((caller(0))[3]);
	my ($bunch, $profile) = @_;
	my @tracks = bunch_tracks($bunch);
	Audio::Nama::pager( qq(effect profile "$profile" created for tracks: @tracks) );
	map { 
		Audio::Nama::EffectChain->new(
			profile 	=> $profile,
			user		=> 1,
			global		=> 1,
			track_name	=> $_,
			ops_list	=> [ $tn{$_}->user_ops ],
			inserts_data => $tn{$_}->inserts,
		);
	} @tracks;
}
sub delete_effect_profile { 
	logsub((caller(0))[3]);
	my $name = shift;
	Audio::Nama::pager( qq(deleting effect profile: $name) );
	map{ $_->destroy} Audio::Nama::EffectChain::find( profile => $name );
}

sub apply_effect_profile {  # overwriting current effects
	logsub((caller(0))[3]);
	my ($profile) = @_;
	my @chains = Audio::Nama::EffectChain::find(profile => $profile);

	# add missing tracks 
	map{ Audio::Nama::pager( "adding track $_" ); add_track($_) } 
		grep{ !$tn{$_} } 
		map{ $_->track_name } @chains;	
	# add effect chains
	map{ $_->add } @chains;
}
sub is_effect_chain {
	my $name = shift;
	my ($fxc) = Audio::Nama::EffectChain::find(name => $name, unique => 1);
	$fxc
}
}
1;
__END__