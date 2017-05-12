package Data::FeatureFactory;

use strict;
use Carp;
use File::Basename;
use Scalar::Util;

our $VERSION = '0.0405';
my $PATH = &{ sub { return dirname( (caller)[1] ) } };
my $OPEN_OPTIONS;
our $CURRENT_FEATURE;
my %KNOWN_FORMATS = map {;$_=>1} qw/binary normal numeric/;

# check if perl can open files in utf8
{
    my $fh;
    undef $@;
    eval { open $fh, '<:encoding(utf8)', $0 };
    if ($@) {
        $OPEN_OPTIONS = '';
        warn qq{the open's :encoding directive not supported by your perl ($]). Files won't be opened in utf8 format.};
    }
    else { $OPEN_OPTIONS = ':encoding(utf8)' }
    close $fh;
}

sub new : method {
    my ($class, $args) = @_;
    $class = ref $class if ref $class;
    croak "Too many parameters to $class->new" if @_ > 2;
    my $self = bless +{}, $class;
    
    if (defined $args) {
        croak "The parameter to ${class}->new must be a hashref with options or nothing" if ref $args ne 'HASH';
        my %accepted_option = map {;$_=>1} qw(N/A);
        while (my ($k, $v) = each %$args) {
            if (not exists $accepted_option{$k}) {
                croak "Unexpected option '$k' passed to ${class}->new"
            }
            if ($k eq 'N/A') {
                $self->{'N/A'} = "$v";
            }
        }
    }
    
    no strict 'refs';
    if (not @{$class."::features"}) {
        croak "\@${class}::features not defined";
    }
    our @features;
    *features = \@{$class."::features"};
    use strict;
    if (not @features) {
        warn "$class has empty set of features. Not much fun";
    }
    $self->{'features'} = [];
    my %feat_named;
    $self->{'feat_named'} = \%feat_named;
    my @featkeys;
    $self->{'featkeys'} = \@featkeys;
    $self->{'caller_path'} = dirname( (caller)[1] );
    
    my %supported_option = ( map {;$_=>1} qw(code default format label name postproc range type values values_file) );
    my %accepted_option  = ( map {;$_=>1} qw(cat2num cat2num_dyna num2cat num2cat_dyna num_values_fh values_ordered) );
    
    # parse the @features array
    for my $original_feature (@features) {
        my $feature = { %$original_feature };
        if (not exists $feature->{'name'}) {
            croak q{There was a feature without a name. Each record in the @features array must be a hashref with a 'name' field at least};
        }
        my $name = $feature->{'name'};
        if (exists $feat_named{$name}) {
            croak "Feature $name specified twice in \@${class}::features";
        }
        push @{ $self->{'features'} }, $feature;
        $feat_named{$name} = $feature;
        push @featkeys, $name;
        
        # Check if there aren't illegal options
        for (keys %$feature) {
            if (not exists $supported_option{$_}) {
                if (exists $accepted_option{$_}) {
                    warn "Option '$_' you specified for feature '$name' is not supported. Be sure you know what you are doing"
                }
                else {
                    croak "Unrecognized option '$_' specified for feature '$name'";
                }
            }
        }
        
        # Check if a postprocessing subroutine is declared
        # If it's a CODEref, we're OK. Else try to load it.
        if (exists $feature->{'postproc'} and ref $feature->{'postproc'} ne 'CODE') {
            my $postproc = $feature->{'postproc'};
            no strict 'refs';
            my $postprocsub = \&{$postproc};
            undef $@;
            eval { $postprocsub->() };
            if ($@ =~ /Undefined subroutine/) {
                my ($package_name) = $postproc =~ /^( (?: \w+:: )+ )/x;
                my $ppname;
                if (defined $package_name and length $package_name > 0) {
                    $package_name =~ s/::$//;
                    local @INC = (@INC, $self->{'caller_path'});
                    undef $@;
                    eval "require $package_name";
                    if ($@) {
                        warn "Failed loading module '$package_name'";
                    }
                    $ppname = $postproc;
                }
                else {
                    $ppname = $class.'::'.$postproc;
                }
                $postprocsub = \&{$ppname};
                undef $@;
                eval { $postprocsub->() };
                if ($@ =~ /^Undefined subroutine/) {
                    croak "Couldn't load postprocessing function '$postproc' ($@)"
                }
            }
            elsif ($@ =~ /^Undefined subroutine/) {
                croak "Couldn't load postprocessing function '$postproc' ($@)"
            }
            $feature->{'postproc'} = $postprocsub;
        }
        
        # Check if values are specified and if they are a list of values.
        if (exists $feature->{'values'}) {
            if (exists $feature->{'values_file'}) {
                croak "Values specified both explicitly and by file for '$name'"
            }
            my $values = $feature->{'values'};
            if (ref $values eq 'HASH') {    # OK, do nothing
            }
            elsif (ref $values eq 'ARRAY') {    # Convert the list to a hash.
                my %values = map {;$_ => 1} @$values;
                $feature->{'values_ordered'} = $values;
                $feature->{'values'} = \%values;
            }
            else {
                my $type;
                if (ref $values) {
                    $type = lc(ref $values).'ref';
                }
                else {
                    $type = lc(ref \$values);
                }
                croak "The values must be specified as an arrayref or hashref, not $type"
            }
        }
        
        if (exists $feature->{'values_file'}) {
            my $values_fn = $feature->{'values_file'};
            my $opened = open my $values_fh, '<'.$OPEN_OPTIONS, $values_fn;
            if (not $opened) {
                open $values_fh, '<'.$OPEN_OPTIONS, $self->{'caller_path'}.'/'.$values_fn
                    or croak "Couldn't open file '$values_fn' specifying values for $name"
            }
            my %values;
            my @values;
            while (<$values_fh>) {
                chomp;
                $values{$_} = 1;
                push @values, $_;
            }
            close $values_fh;
            $feature->{'values'} = \%values;
            $feature->{'values_ordered'} = \@values;
        }
        
        if (exists $feature->{'range'}) {
            if (exists $feature->{'values'}) {
                croak "Both range and values specified for feature '$name'"
            }
            $feature->{'range'} =~ /^ (.+?) \s* \.{2,} \s* (.+) $/x
            or croak "Malformed range '$$feature{range}' of feature '$name'. Should be in format '0 .. 5'";
            my $l = $1+0;
            my $r = $2+0;
            if (not $l < $r) {
                croak "Invalid range '$$feature{range}' specified for feature '$name'. The left boundary must be lesser than the right one"
            }
            
            if ($feature->{'type'} =~ /^int/i) {
                $feature->{'values'} = {map {;$_ => 1} $l .. $r};
                $feature->{'values_ordered'} = [$l .. $r];
            }
            elsif ($feature->{'type'} =~ /^num/i) { 
                $feature->{'range_l'} = $l;
                $feature->{'range_r'} = $r;
            }
        }
        
        if (exists $feature->{'default'}) {
            if (not exists $feature->{'values'} and not exists $feature->{'range_l'}) {
                croak "Default value '$$feature{default}' but no values specified for feature '$name'"
            }
        }
        
        if (exists $feature->{'type'}) {
            my $type = lc substr $feature->{'type'}, 0, 3;
            my $type_OK = grep {$type eq $_} qw(boo int num cat);
            if (not $type_OK) {
                croak "The type of a feature, if given, should be 'integer', 'numeric', or 'categorial'"
            }
            $feature->{'type'} = $type;
            
            # check if the values comply to the type
            if ($type eq 'boo') {
                if (exists $feature->{'values'}) {
                    my @values = exists $feature->{'values_ordered'} ? @{ $feature->{'values_ordered'} } : values(%{ $feature->{'values'} });
                    if (@values > 2) {
                        my $num_values = @values;
                        croak "More than two values ($num_values) specified for feature '$name'"
                    }
                    my ($false, $true);
                    # boolify the values
                    for (@values) {
                        if ($_) {
                            if (defined $true) {
                                croak "True value (literal: '$true', '$_') for feature '$name' specified multiple times"
                            }
                            $true = $_;
                        }
                        else {
                            if (defined $false) {
                                croak "False value (literal: '$false', '$_') for feature '$name' specified multiple times"
                            }
                            $false = $_;
                        }
                        $_ = $_ ? 1 : 0;
                    }
                    if (exists $feature->{'values_ordered'}) {
                        $feature->{'values_ordered'} = \@values;
                    }
                    $feature->{'values'} = +{ map {;$_=>1} @values };
                }
                else {
                    $feature->{'values'} = {0 => 1, 1 => 1};
                    $feature->{'values_ordered'} = [0,1];
                }
                if (exists $feature->{'default'}) {
                    my $def = $feature->{'default'};
                    my @vals = values %{ $feature->{'values'} };
                    if (@vals > 1) {
                        croak "Default value '$def' specified for boolean feature '$name' which has both values allowed"
                    }
                    unless ($def xor $vals[0]) {
                        my $val = $def ? 'true' : 'false';
                        croak "Default and allowed value are both $val for feature '$name'";
                    }
                    $feature->{'default'} = $def ? 1 : 0;
                }
            }
            elsif ($type eq 'int') {
                if (exists $feature->{'values'}) {
                    my @values = exists $feature->{'values_ordered'} ? @{ $feature->{'values_ordered'} } : values(%{ $feature->{'values'} });
                    # integrify the values
                    for (@values) {
                        $_ = int $_;
                    }
                    if (exists $feature->{'values_ordered'}) {
                        $feature->{'values_ordered'} = \@values;
                    }
                    $feature->{'values'} = +{ map {;$_=>1} @values };
                }
                if (exists $feature->{'default'}) {
                    $feature->{'default'} = int $feature->{'default'};
                }
            }
            elsif ($type eq 'num') {
                # numify the features, producing warnings if used
                if (exists $feature->{'values'}) {
                    my @values = exists $feature->{'values_ordered'} ? @{ $feature->{'values_ordered'} } : values(%{ $feature->{'values'} });
                    for (@values) {
                        $_ += 0;
                    }
                    if (exists $feature->{'values_ordered'}) {
                        $feature->{'values_ordered'} = \@values;
                    }
                    $feature->{'values'} = +{ map {;$_=>1} @values };
                }
                if (exists $feature->{'default'}) {
                    $feature->{'default'} += 0;
                }
            }
        }
        
        if (exists $feature->{'format'}) {
            my $format = $feature->{'format'};
            if (not $format =~ /^ (?: normal | numeric | binary ) $/x) {
                croak "Invalid format '$format' specified for feature '$name'. Please specify 'normal', 'numeric' or 'binary'"
            }
            if (not exists $feature->{'values'} and $format eq 'binary') {
                croak "Feature '$name' has format: 'binary' specified but doesn't have values specified"
            }
        }
        
        # find the actual code of the feature
        my $code;
        no strict 'refs';
        if (exists $feature->{'code'}) {
            $code = $feature->{'code'};
            if (ref $code ne 'CODE') {
                croak "'code' was specified for feature '$name' but it's not a coderef"
            }
        }
        elsif (%{$class.'::features'} and exists ${$class.'::features'}{$name}) {
            $code = ${$class.'::features'}{$name};
            if (ref $code ne 'CODE') {
                croak "Found $name in \%${class}::features but it's not a coderef"
            }
        }
        else {
            $code = *{$class.'::'.$name}{CODE};
            if (ref $code ne 'CODE') {
                croak "Couldn't find the code (function) for feature '$name'. Define it as a function '$name' in the '$class' package. Stopped"
            }
        }
        $feature->{'code'} = $code;
        
        if (exists $feature->{'label'}) {
            my $label = $feature->{'label'};
            if (ref $label eq 'ARRAY') {
                $feature->{'label'} = {map {;uc($_) => 1} @$label};
            }
            elsif (ref $label) {
                croak "Label must be a string or an array of strings - feature '$name' has a ".ref($label).'ref'
            }
            else {
                $feature->{'label'} = {uc($label) => 1};
            }
        }
    }
#    print map "*$_\n", map keys(%$_), @{ $self->{'features'} };
    return $self
}

sub expand_names : method {
    my ($self, $featnames) = @_;
    if (not ref $featnames and exists $self->{expand_names_cache}{$featnames}) {
        return $self->{expand_names_cache}{$featnames}
    }
    my $orig_featnames = $featnames;
    my @featkeys = @{ $self->{'featkeys'} };
    my %feat_named = %{ $self->{'feat_named'} };
    
    if ($featnames eq 'ALL') {
        $featnames = \@featkeys;
    }
    elsif (ref $featnames eq 'ARRAY') {
#        $featnames = [@$featnames]; # make a copy
    }
    # features given by labels
    elsif ($featnames !~ /[[:lower:]]/ and $featnames =~ /[[:upper:]]/) {
        my @all_labels = split /\s+/, $featnames;
        my @plus_labels  = map {s/^\+//; $_}  grep {substr($_, 0, 1) ne '-'} @all_labels;
        my @minus_labels = map {substr $_, 1} grep {substr($_, 0, 1) eq '-'} @all_labels;
        # Specifying just '-LABEL' means all but those that have LABEL
        if (@plus_labels == 0 and @minus_labels > 0) {
            @plus_labels = qw(ALL);
        }
        if (grep {$_ eq 'ALL'} @minus_labels) {
            croak "Label 'ALL' is special and can't be used with the minus sign, as in $featnames"
        }
        $featnames = [];
        for my $featkey (@featkeys) {
            my $feature = $feat_named{ $featkey };
            my $included = grep { $_ eq 'ALL' or exists $feature->{'label'}{$_} } @plus_labels;
            my $excluded = grep {                exists $feature->{'label'}{$_} } @minus_labels;
            push @$featnames, $featkey if $included and not $excluded;
        }
    }
    else {
        $featnames = ["$featnames"];
    }
    
    if (not ref $orig_featnames) { $self->{expand_names_cache}{$orig_featnames} = $featnames }
    return $featnames
}

sub evaluate : method {
    my ($self, $featnames, $format, @args) = @_;
    my $class = ref $self;
    
    $featnames = $self->expand_names($featnames);
    my @feats;
    if (exists $self->{evaluate_featnames_cache}{"@$featnames"}) {
        @feats = @{ $self->{evaluate_featnames_cache}{"@$featnames"} };
    }
    else {
        my %feat_named = %{ $self->{feat_named} };
        for my $featname (@$featnames) {
            if (not exists $feat_named{$featname}) {
                croak "Feature '$featname' you wish to evaluate was not found among known features (these are: @{$self->{featkeys}})"
            }
            push @feats, $feat_named{$featname};
        }
        $self->{evaluate_featnames_cache}{"@$featnames"} = \@feats;
    }
    
    if (not exists $KNOWN_FORMATS{$format}) {
        croak "Unknown format: '$format'. Please specify one of: @{[keys %KNOWN_FORMATS]}."
    }
    for my $feature (@feats) {
        $self->_create_mapping($feature, $format);
    }
    
    if (@args == 0) {
        warn 'No arguments specified for the features.';
    }
    ### Done argument checking.
    
    ### Traverse the features and evaluate them
    my @rv;
    for my $feature (@feats) {
        my $name = $feature->{'name'};
        $CURRENT_FEATURE = $name;
        my $normrv = $feature->{'code'}(@args);
        undef $CURRENT_FEATURE;
        my $format = exists $feature->{'format'} ? $feature->{'format'} : $format;
        
        if (not defined $normrv and exists $self->{'N/A'}) {
            my $na = $self->{'N/A'};
            if (exists $feature->{'type'} and $feature->{'type'} eq 'boo') {
                push @rv, $na;
            }
            elsif ($format eq 'binary') {
                # take one of the vectors in cat2bin
                my @dummy = @{ (values %{ $feature->{'cat2bin'} })[0] };
                if (not @dummy) {
                    croak "Couldn't determine the length of bit vector for feature '$name',"
                         ."which was about to be evaluated in binary and returned undef"
                }
                push @rv, map $na, @dummy;
            }
            else {
                push @rv, $na;
            }
        }
        else {
            # Normally format the value. The eval babble is there to take care of unexpected values.
            undef $@;
            my @val = eval { _format_value($feature, $normrv, $format, @args) };
            if ($@) {
                if (ref $@ and $@->isa('Data::FeatureFactory::SoftError')) {
                    warn ${$@};
                    return
                }
                else {
                    die $@
                }
            }
            push @rv, @val;
        }
    }
    
    return @rv[0 .. $#rv]
}

sub _format_value {
    my ($feature, $normrv, $format, @args) = @_;
    my @rv;
    my $name = $feature->{'name'};
    local $\; local $,;
    
    # convert to number if appropriate
    if (exists $feature->{'type'}) {
        my $type = $feature->{'type'};
        if ($type eq 'num' or $type eq 'int') {
            $normrv += 0;
        }
        if ($type eq 'int') {
            $normrv = int $normrv;
        }
        if ($type eq 'boo') {
            $normrv = $normrv ? 1 : 0;
        }
    }
    
    # check if the value is a legal one
    if (exists $feature->{'values'}) {
        if (exists $feature->{'values'}{$normrv}) {    # alles gute
        }
        elsif (exists $feature->{'default'}) {
            $normrv = $feature->{'default'};
        }
        else {
            die Data::FeatureFactory::SoftError->new("Feature '$name' returned unexpected value '$normrv' on arguments '@args'")
        }
    }
    # check the range for numeric features
    elsif (exists $feature->{'range_l'}) {
        if (not exists $feature->{'range_r'}) {
            die "feature '$name' has range_l but not range_r";
        }
        if ($normrv < $feature->{'range_l'}) {
            if (exists $feature->{'default'}) {
                $normrv = $feature->{'default'};
            }
            else {
                die Data::FeatureFactory::SoftError->new(
                    "Feature '$name' returned an unexpected value '$normrv' below the left allowed boundary '$$feature{range_l}'"
                )
            }
        }
        if ($normrv > $feature->{'range_r'}) {
            if (exists $feature->{'default'}) {
                $normrv = $feature->{'default'};
            }
            else {
                die Data::FeatureFactory::SoftError->new(
                    "Feature '$name' returned an unexpected value '$normrv' above the right allowed boundary '$$feature{range_r}'"
                )
            }
        }
    }
    
    if ($format eq 'normal') {
        if (exists $feature->{'postproc'}) {
            $normrv = $feature->{'postproc'}->($normrv);
        }
        @rv = ($normrv);
    }
    elsif ($format eq 'numeric') {
        if (exists $feature->{'type'} and $feature->{'type'} =~ /^( num | int | boo )$/x) {
            @rv = ($normrv);
        }
        elsif (exists $feature->{'cat2num'}) {
            if (not exists $feature->{'cat2num'}{$normrv}) {
                croak "Feature '$name' has the value '$normrv' for which there is no mapping to numbers"
            }
            @rv = ($feature->{'cat2num'}{$normrv});
        }
        else {  # dynamically creating the mapping
            my $n;
            if (exists $feature->{'cat2num_dyna'}{$normrv}) {
                $n = $feature->{'cat2num_dyna'}{$normrv};
            }
            else {
                $n = ++$feature->{'num_value_max'};
                $feature->{'cat2num_dyna'}{$normrv} = $n;
                $feature->{'num2cat_dyna'}{$n} = $normrv;
                my @toprint = ($normrv, $n);
                if (exists $feature->{'postproc'}) {
                    my $ppd = $feature->{'postproc'}->($normrv);
                    $feature->{'pp2cat_dyna'}{$ppd} = $normrv;
                    push @toprint, $ppd;
                }
                print {$feature->{'num_values_fh'}} join("\t", @toprint)."\n"
                or croak "Couldn't print the mapping of categorial value '$normrv' to numeric value '$n' for feature '$name' to a file ($!).\n"
                . 'Please provide a list of values for the feature to avoid this'
            }
            @rv = ($n);
        }
    }
    elsif ($format eq 'binary') {
        if (exists $feature->{'type'} and $feature->{'type'} eq 'boo') {
            @rv = ($normrv);
        }
        elsif (not exists $feature->{'cat2bin'}{$normrv}) {
            croak "No mapping for value '$normrv' to binary in feature '$name'"
        }
        else {
            @rv = @{ $feature->{'cat2bin'}{$normrv} };
        }
    }
    else {
        croak "Unrecognized format '$format'"
    }
    return @rv
}

sub _values_of {
    my ($feature) = @_;
    my @values;
    if (exists $feature->{'values_ordered'}) {
        @values = @{ $feature->{'values_ordered'} };
    }
    elsif (exists $feature->{'values'}) {
        @values = keys %{ $feature->{'values'} };
    }
    else {
        croak "Attempted to gather the values of feature '$$feature{name}', which has none specified"
    }
    if (exists $feature->{'default'} and not exists $feature->{'values'}{ $feature->{'default'} }) {
        push @values, $feature->{'default'};
    }
    return @values
}

sub _create_mapping : method {
    my ($class, $feature, $format) = @_;
    $class = ref $class if ref $class;
    if (exists $feature->{'format'} and $format ne 'postprocd') {
        $format = $feature->{'format'};
    }
    
    if (lc $format eq 'normal') {
    }
    elsif (lc $format eq 'numeric') {
        return if exists $feature->{'type'} and $feature->{'type'} eq 'num';
        return if exists $feature->{'type'} and $feature->{'type'} eq 'int';
        return if exists $feature->{'type'} and $feature->{'type'} eq 'boo';
        return if exists $feature->{'cat2num'}; # Blindly trusting that what we have here is a sane mapping from the original values to numbers
        my $name = $feature->{'name'};
        if (not exists $feature->{'values'}) {
            return if exists $feature->{'num_values_fh'};
            warn "Categorial feature '$name' is about to be evaluated numerically but has no set of values specified";
            (my $num_values_basename = $class.'__'.$name) =~ s/\W/_/g;
            $num_values_basename = '.FeatureFactory.'.$num_values_basename;
            my @filenames_to_try = (
                $PATH.'/'.$num_values_basename,
                $ENV{'HOME'}.'/'.$num_values_basename,
                '/tmp/'.$num_values_basename,
            );
            my $num_values_fh;
            my $opened;
            my $num_value_max = 0;
            FILENAME_R:
            for my $fn (@filenames_to_try) {
                $opened = open my $fh, '+<'.$OPEN_OPTIONS, $fn;
                if ($opened) {
                    local $_;   # for some reason, this is necessary to prevent crashes (Modification of read-only value) when e.g. in for(qw(a b)){ }
                    while (<$fh>) {
                        chomp;
                        my ($cat, $num, $ppd) = split /\t/;
                        $num_value_max = $num if $num > $num_value_max;
                        $feature->{'cat2num_dyna'}{$cat} = $num;
                        $feature->{'num2cat_dyna'}{$num} = $cat;
                        $feature->{'pp2cat_dyna' }{$ppd} = $cat if defined $ppd;
                    }
                    print STDERR "Saving the mapping for feature '$name' to file $fn\n";
                    $feature->{'num_values_fh'} = $fh;
                    last FILENAME_R
                }
            }
            # If there's no file to recover from, try to start a new one
            if (not $opened) { FILENAME_W: for my $fn (@filenames_to_try) {
                $opened = open my $fh, '>'.$OPEN_OPTIONS, $fn;
                if ($opened) {
                    print STDERR "Saving the mapping for feature '$name' to file $fn\n";
                    $feature->{'num_values_fh'} = $fh;
                    last FILENAME_W
                }
            }}
            if (not $opened) {
                delete $feature->{'num_values_fh'};
                croak "Couldn't open a file for saving the mapping the categories of feature '$name' to numbers. "
                . 'Please specify the values for the feature to avoid this'
            }
            $feature->{'num_value_max'} = $num_value_max;
        }
        else {  # Got values specified - create a mapping
            my @values = _values_of($feature);
            my $n = 1;
            for my $value (@values) {
                $feature->{'cat2num'}{$value} = $n;
                $feature->{'num2cat'}{$n} = $value;
            } continue {
                $n++;
            }
        }
    }
    elsif (lc $format eq 'binary') {
        return if exists $feature->{'type'} and $feature->{'type'} eq 'boo';
        return if exists $feature->{'cat2bin'};
        my $name = $feature->{'name'};
        if (not exists $feature->{'values_ordered'} and not exists $feature->{'values'}) {
            croak "Attempted to convert feature '$name' to binary without specifying its values";
        }
        
        my @values = _values_of($feature);
        
        my $n = 0;
        my @zeroes = (0) x scalar(@values);
        for my $value (@values) {
            my @vector = @zeroes;
            $vector[$n] = 1;
            $feature->{'cat2bin'}{$value} = \@vector;
            $feature->{'bin2cat'}{join(' ', @vector)} = $value;
        } continue {
            $n++;
        }
    }
    elsif ($format eq 'postprocd') {
        return if exists $feature->{'pp2cat'};
        my $name = $feature->{'name'};
        if (not exists $feature->{'postproc'}) {
            croak "Feature '$name' doesn't have a postprocessing function specified - can't create mapping from postprocessed values. Stopped"
        }
        my $ppfun = $feature->{'postproc'};
        my @values = _values_of($feature);
        my %pp2cat;
        for my $value (@values) {
            my $ppd = $ppfun->($value);
            $pp2cat{ $ppd } = $value;
        }
        $feature->{'pp2cat'} = \%pp2cat;
    }
    else {
        croak "Format '$format' not recognized - please specify 'normal', 'numeric', 'binary' or 'postprocd' (should have caught this earlier)"
    }
}

sub names : method {
    my ($self) = @_;
    return map $_->{'name'}, @{ $self->{'features'} }
}

sub _vector_length { # how many bits will the binary representation of this feature have
    my ($feature) = @_;
    if (exists $feature->{'type'} and $feature->{'type'} eq 'boo') {
        return 1
    }
    return scalar _values_of($feature)
}

sub _shift_value {
    my ($feature, $format, $values) = @_;
    if ($format ne 'binary') {
        return shift @$values
    }
    my $n = _vector_length($feature);
    if (@$values < $n) {
        croak "There's not enough fields left to shift a $format value (width $n) of feature '$$feature{name}' from a length "
        . scalar(@$values) . " list ('@$values')"
    }
    return splice @$values, 0, $n
}

sub _init_translation {
    my ($self, $names, $options) = @_;
    if (ref($names) ne 'ARRAY') {
        croak 'Names must be given by an arrayref'
    }
    if (ref($options) ne 'HASH') {
        croak 'Options must be given by a hashref'
    }
    
    my %accepted_options = map {;$_=>1} qw(
        names from_format to_format from_NA to_NA FS OFS header ignore
    );
    for (keys %$options) {
        if (not exists $accepted_options{$_}) {
            croak "Translate does not accept option '$_'. Accepted options are: ".join(' ', keys %accepted_options).'. Stopped'
        }
    }
    
    my $from_format = $options->{'from_format'};
    my $to_format   = $options->{'to_format'};
    for ($from_format, $to_format) {
        if (! m/^(?: normal | numeric | binary )$/x) {
            croak '{to,from}_format must be one of "normal", "numeric" or "binary"'
        }
    }
    
    if (exists $options->{'from_NA'} and exists $options->{'to_NA'}) {
    }
    elsif (exists $options->{'from_NA'} and exists $self->{'N/A'}) {
        $options->{'to_NA'}   = $self->{'N/A'};
    }
    elsif (exists $options->{'to_NA'}   and exists $self->{'N/A'}) {
        $options->{'from_NA'} = $self->{'N/A'};
    }
    elsif (exists $options->{'to_NA'}) {
        $options->{'from_NA'} = undef;
    }
    elsif (exists $options->{'from_NA'}) {
        croak 'from_NA specified but neither to_NA nor global N/A value specified'
    }
    elsif (exists $self->{'N/A'}) {
        $options->{'from_NA'} = $options->{'to_NA'} = $self->{'N/A'};
    }
    
    if (exists $options->{'header'} and not $options->{'header'}) {
        delete $options->{'header'};
    }
    
    if (exists $options->{'ignore'}) {
        my $ignore = $options->{'ignore'};
        $options->{'ignore'} = [];
        
        if (not ref $ignore) {
            $ignore = [$ignore];
        }
        
        if (ref($ignore) eq 'ARRAY') {
            my $has_non_nums = grep !Scalar::Util::looks_like_number($_), @$ignore;
            if ($has_non_nums) {
                warn 'Some of the specifications of columns to ignore are non-numeric'
            }
            for my $idx (@$ignore) {
                if ($idx < 0) {
                    croak "Negative column indices aren't currently supported. Trailing columns are ignored always. Stopped"
                }
                $options->{'ignore'}[ $idx ] = 1;
            }
        }
        else {
            croak 'Option "ignore" can only be a column number or an array thereof. Stopped'
        }
        
        # Remove the names of the columns to ignore if the names come from a header
        if (exists $options->{'header'}) {
            for my $idx (sort {$b <=> $a} @$ignore) {
                splice @$names, $idx, 1;
            }
        }
    }
    
    my (@features, @widths);
    my %names = map {;$_=>1} $self->names;
    for my $name (@$names) {
        if (not exists $names{$name}) {
            croak "Feature '$name' not found among ".join(' ', $self->names).". Stopped"
        }
        my $feature = $self->{'feat_named'}{ $name };
        $self->_create_mapping($feature, $from_format);
        $self->_create_mapping($feature, $to_format);
        if ($from_format eq 'normal' and exists $feature->{'postproc'}) {
            if (exists $feature->{'values'}) {
                $self->_create_mapping($feature, 'postprocd');
            }
            elsif (exists $feature->{'format'} or $to_format eq 'normal') {
                # translating normal -> normal -- kein problem
            }
            elsif (join(' ', sort $from_format, $to_format) eq 'normal numeric') {
                # translating with dynamic mapping
            }
            else {
                croak "Feature '$name' is postprocessed and about to be translated from normal but has no values specified. Stopped"
            }
        }
        push @features, $feature;
        my $bin = 0;
        if (exists $feature->{'format'} and $feature->{'format'} eq 'binary') {
            $bin = 1;
        }
        elsif (exists $feature->{'format'}) {}
        elsif ($from_format eq 'binary') {
            $bin = 1;
        }
        my $width = $bin ? _vector_length($feature) : 1;
        push @widths, $width;
    }
    return map [$names->[$_], $features[$_], $widths[$_]], 0 .. $#features
}

my %x2cat = (
    binary    => 'bin2cat',
    numeric   => 'num2cat',
    postprocd => 'pp2cat',
);

sub _translate_row : method {
    my ($self, $descrs, $values, $options) = @_;
    if (ref($values) ne 'ARRAY') {
        croak 'Values must be given by an arrayref'
    }
    if (@$values < @$descrs) {
        croak "There's not enough values in the \@values array (".scalar(@$values).") to match the number of features (".scalar(@$descrs).")";
    }
    my ($from_format, $to_format, $from_NA, $to_NA, $ignore) = @$options{qw(
         from_format   to_format   from_NA   to_NA   ignore)};
    
    my $coln = 0;
    my @rv;
    FEATNAME:
    for my $descr (@$descrs) {
        my ($name, $feature, $width) = @$descr;
        if (defined $ignore) {
            while (exists $ignore->[ $coln++ ]) {
                push @rv, shift @$values;
            }
        }
        my $from_format = exists $feature->{'format'} ? $feature->{'format'} : $from_format;
        my $to_format   = exists $feature->{'format'} ? $feature->{'format'} : $to_format;
        my @value = splice @$values, 0, $width;
        if (@value == 0) {
            croak "Zero-width value obtained for feature '$name'"
        }
        
        # Check if the value is N/A
        my $is_NA = 0;
        if (@value == 1) {
            my $value = $value[0];
            if (defined $from_NA and $value eq $from_NA) {
                $is_NA = 1;
            }
            elsif (defined $to_NA and not defined $value and not defined $from_NA) {
                $is_NA = 1;
            }
        }
        else {
            if (defined $to_NA and not grep {defined $_} @value and not defined $from_NA) {
                $is_NA = 1;
            }
            elsif (defined $from_NA and not grep {$_ ne $from_NA} @value) {
                $is_NA = 1;
            }
        }
        
        # Append the N/A if appropriate
        if ($is_NA) {
            my $n = $to_format eq 'binary' ? _vector_length($feature) : 1;
            push @rv, ( ($to_NA) x $n );
            next FEATNAME
        }
        
        if ($from_format eq $to_format) {
            push @rv, @value;
            next FEATNAME
        }
        else {
            my $catval;
            my $from_format = $from_format;
            if ($from_format eq 'normal' and exists $feature->{'postproc'}) {
                $from_format = 'postprocd';
            }
            if ($from_format eq 'normal') {
                ($catval) = @value;
            }
            elsif ($from_format eq 'numeric' and exists $feature->{'type'} and $feature->{'type'} =~ /^(int|num|boo)$/) {
                ($catval) = @value;
            }
            elsif ($from_format eq 'binary' and exists $feature->{'type'} and $feature->{'type'} eq 'boo') {
                ($catval) = @value;
            }
            else {
                my $transfer = $x2cat{ $from_format };
                if (not defined $transfer) {
                    croak "Internal error: Unexpected value for \$from_format: '$from_format'"
                }
                if (not exists $feature->{ $transfer }) {
                    if (exists $feature->{ $transfer.'_dyna' }) {
                        $transfer = $transfer.'_dyna';
                    }
                    else {
                        croak "Cannot find mapping '$transfer' for feature '$name'"
                    }
                }
                my $valval = join(' ', @value);
                if (not exists $feature->{ $transfer }{ $valval }) {
                    my $hint = '';
                    if ($valval eq $feature->{'name'}) {
                        $hint = ". Maybe you forgot there was a header in your file? Stopped"
                    }
                    croak "Unexpected value '$valval' of feature '$name' for transfer '$transfer'$hint"
                }
                $catval = $feature->{ $transfer }{ $valval };
            }
            
            my @formatted = _format_value($feature, $catval, $to_format, 'NO_ARGS:TRANSLATING_ONLY');
            push @rv, @formatted;
        }
    }
    
    # Append the trailing columns
    push @rv, @$values;
    
    return @rv
}

sub translate_row : method {
    my ($self, $names, $values, $options) = @_;
    $names = $self->expand_names($names);
    my @descrs = $self->_init_translation($names, $options);
    $self->_translate_row(\@descrs, $values, $options);
}

sub translate : method {
    my ($self, $source, $sink, $options) = @_;
    local $\; local $,;
    if (not defined Scalar::Util::openhandle($source)) {
        croak 'Source must be given by an open filehandle'
    }
    if (not defined Scalar::Util::openhandle($sink)) {
        croak 'Destination must be given by an open filehandle'
    }
    if (ref($options) ne 'HASH') {
        croak 'Options must be given by a hashref'
    }
    my $ifs = $options->{'FS'};
    my $ofs = exists $options->{'OFS'} ? $options->{'OFS'} : $ifs;
    my @names;
    my @orig_header_fields;
    if (exists $options->{'names'}) {
        @names = @{ $self->expand_names($options->{'names'}) };
    }
    elsif (exists $options->{'header'} and $options->{'header'}) {
        my $row = <$source>;
        chomp $row;
        @names = split /(?:\Q$ifs\E)+/, $row;
        @orig_header_fields = @names;
    }
    else {
        croak 'No feature names specified for translate'
    }
    
    my @descrs = $self->_init_translation(\@names, $options);
    
    # Translate the header, if there's one.
    if (@orig_header_fields) {
        my $globbin = $options->{'to_format'} eq 'binary';
        my $last = pop @orig_header_fields;
        for my $field (@orig_header_fields) {
            my $nsep;
            if (not exists $self->{'feat_named'}{ $field }) {
                $nsep = 1;
            }
            else {
                my $feature = $self->{'feat_named'}{ $field };
                my $bin = (exists $feature->{'format'} and $feature->{'format'} eq 'binary' or $globbin);
                $nsep = $bin ? _vector_length($feature) : 1;
            }
            print {$sink} $field, $ofs x $nsep;
        }
        print {$sink} $last, "\n";
    }
    
    ROW:
    while (defined (my $row = <$source>)) {
        chomp $row;
        my @values = split /$ifs/, $row;
        undef $@;
        my @translated = eval { $self->_translate_row(\@descrs, \@values, $options) };
        warn("$@ (line $.)"), next ROW if $@;
        print {$sink} join($ofs, @translated), "\n";
    }
}

sub add_label {
    my ($feature, @labels) = @_;
    @labels = map uc($_), @labels;
    if (exists $feature->{'label'}) {
        if (ref($feature->{'label'}) eq 'ARRAY') {
            push @{ $feature->{'label'} }, @labels;
        }
        else {
            $feature->{'label'} = [$feature->{'label'}, @labels];
        }
    }
    else {
        $feature->{'label'} = [@labels];
    }
}

{
    package Data::FeatureFactory::SoftError;
    sub new {
        my ($class, $message) = @_;
        $message = "SoftError occurred" if not defined $message;
        return bless \$message, $class
    }
}

1

__END__

=head1 NAME

Data::FeatureFactory - evaluate features normally or numerically

=head1 SYNOPSIS

 # in the module that defines features
 package MyFeatures;
 use base qw(Data::FeatureFactory);
 
 our @features = (
    { name => 'no_of_letters', type => 'int', range => '0 .. 5' },
    { name => 'first_letter',  type => 'cat', 'values' => ['a' .. 'z'] },
 );
 
 sub no_of_letters {
    my ($word) = @_;
    return length $word
 }
 
 sub first_letter {
    my ($word) = @_;
    return substr $word, 0, 1
 }

 # in the main script
 package main;
 use MyFeatures;
 my $f = MyFeatures->new;
 
 # evaluate all the features on all your data and format them numerically
 open FILEHANDLE, '>my_features.txt';
 print FILEHANDLE join(' ', $f->names), "\n";   # prepend a header
 for my $record (@data) {
     my @values = $f->evaluate('ALL', 'numeric', $record);
     print FILEHANDLE join(' ', @values);
 }
 close FILEHANDLE;
 
 # specify the features to evaluate and gather the result in binary form
 my @vector = $f->evaluate([qw(no_of_letters first_letter)], 'binary', 'foo');

 # translate the once evaluated features to other formats
 open SOURCE, 'my_features.txt';
 open SINK,  '>my_features.csv';
 $f->translate(SOURCE, SINK, {
    from_format => 'numeric', to_format => 'normal',
    FS => ' ', OFS => ',',  # fields from space-separated to comma-separated
    header => 1,    # the names of the features are in the first row of SOURCE
    # names => 'ALL',    # header specified, so we don't need this    
    from_NA => 0, to_NA => 'N/A'    # interpret zeroes as N/A's and substitute
 });

=head1 DESCRIPTION

Data::FeatureFactory automates evaluation of features of data samples and optionally
encodes them as numbers or as binary vectors.

=head2 Defining features

The features are defined as subroutines in a package inheriting from Data::FeatureFactory.
A subroutine is declared to be a feature by being mentioned in the package array
C<@features>. Options for the features are also specified in this array. Its
minimum structure is as follows:

 @features = (
    { name => "name of feature 1" },
    { name => "name of feature 2" },
    ...
 )

The elements of the array must be hashrefs and each of them must have a C<name>
field. Other fields can specify options for the features. These are:

=over 4

=item type

Specifies if the feature is C<categorial>, C<numeric>, C<integer> or
C<boolean>.  Only the first three characters, case insensitive, are considered,
so you can as well say C<cat>, C<Num>, C<integral> or C<Boo!>. The default type
is categorial.

Integer and numeric features will have values forced to numbers. Boolean ones
will have values converted to 1/0 depending on Perl's notion of True/False. If
you use warnings, you'll get one if your numeric feature returns a non-numeric
string.

=item values

Lists the acceptable values for the feature to return. If a different value is
returned by the subroutine, the whole feature vector is discarded.
Alternatively, a default value can be specified. Whenever the order of the
values matters, it is honored (as in transfer to numeric format). The values can
be specified as an arrayref (in which case the order is regarded) or as a
hashref, in which case the values are pseudo-randomly ordered, but the loading
time is faster and transfer to numeric or binary format is faster as well. If
the values are specified as a hashref, then keys of the hash shall contain the
values of the feature and values of the hash should be 1's.

=item default

Specifies a default value to be substituted when the feature returns something
not listed in C<values>.

=item values_file

The values can either be listed directly or in a file. This option specifies
its name. This option must not appear in combination with the C<values> option.
Each value shall be on one line, with no headers, no intervening whitespace no
comments and no empty lines.

The file is expected to be encoded in UTF-8 on perls supporting the C<:encoding>
discipline for the C<open> function.

=item range

In case of integer and numeric features, an allowed range can be specified
instead of the values. This option cannot appear together with the C<values> or
C<values_file> option. The behavior is the same as with the C<values> option.
The interval specified is closed, so returning the limit value is OK. The range
shall be specified by two numeric expressions separated by two or more dots with
optional surrounding whitespace - for example 2..5 or -0.5 ...... +1.000_005.
The stuff around the dots are not checked to be valid numeric expressions. But
you should get a warning if you use them when you supply something nonsensical.

You can also specify a range for numeric (non-integer) features. The return
value will be checked against it but unlike integer features, this will not
generate a list of acceptible values. Therefore, range is not enough to specify
for a numeric feature if you want to have it converted to binary. (though
converting floating-point values to binary vectors seems rather quirky by
itself)

=item postproc

This option defines a subroutine that is to be used as a filter for the
feature's return value. It comes in handy when you, for example, have a feature
returning UTF-8 encoded text and you need it to appear ASCII-encoded but you
need to specify the acceptable values in UTF-8. As this use-case suggests, the
postprocessing takes place after the value is checked against the list of
acceptable values. The value for this option shall either be a coderef or the
name of the preprocessing function. If the function is not available in the
current namespace, Data::FeatureFactory will attempt to find it.

The postprocessing only takes place when the feature is evaluated normally -
that is, when its output is not being transformed to numeric or binary format.

=item code

Normally, the features are defined as subroutines in the package that inherits
from Data::FeatureFactory. However, the definition can also be provided as a coderef
in this option or in the C<%features> hash of the package. The priority is: 1)
the C<code> option, 2) the C<%features> hash, and 3) the package subroutine.

=item format

Features can be output in different ways - see below. The format in which the
features are evaluated is normally specified for all features in the call to
C<evaluate>. You can override it for specific features with this option.

You'll mostly use this to prevent the target (to-predict) feature from being
numified or binarified: { name => 'target', format => 'normal' }.

=item label

The value of this field can either be a string or an arrayref specifying a list
of labels for the feature. It's usable when you want to evaluate a group of
features without having to list them.

See the C<evaluate> method for details.

=back

=head3 Notice

Both the feature and the optional postprocessing routine are evaluated
in scalar context.

When the N/A option is used, then C<undef> is treated specially but if N/A is
not specified, then it is not. Assume you have a feature with values specified,
a default value and the feature returns undef. Then if you use the N/A option,
the N/A value is substituted, but if you don't use the N/A option, the default
value is substituted instead (or it is left as an empty string if it's a valid
value).

The postprocessing subroutine, if specified, can be called several times during
the construction of the object and within any methods. So it's highly advisable
for postprocessing subroutines to have no side-effects.

=head2 Creating the features object

The C<new> method creates an
object that can then be used to evaluate features. Please do *not* override the
C<new> method. If you do, then be sure that it calls
C<Data::FeatureFactory::new> properly. This method accepts an optional
argument - a hashref with options. Currently, only the 'N/A' option is
supported. See below for details.

=head2 Getting the list of defined features

The C<names> method returns a list of names of all the features defined.

=head2 Evaluating features

The C<evaluate> method of Data::FeatureFactory takes these
arguments: 1) names of the features to evaluate, 2) the format in which they
should be output and 3) arguments for the features themselves.

The first argument can be an arrayref with the names of the features, or it can
be a string. In case it's a string containing lowercase letters, then it's
interpreted as the name of the only feature to evaluate.
If all the letters in the string are UPPERCASE, then it's interpreted as a
whitespace-separated list of labels. Each label can be prefixed by a C<-> sign
or a C<+> sign. No prefix is the same as the C<+> prefix. The features evaluated
are then those, who have at least one C<+>label but no C<->label. The presence
of a negative label overrides the presence of a positive one in case of
collisions. There is a special label C<ALL>, which you should never define for a
feature and which will match any feature. It must not be used with the minus
sign. Only specifying negative labels implies the C<ALL> label, so you can write
C<-TARGET> to get all but the target features. The features are sorted by how
they appear in the @features array - the order of labels has no effect
whatsoever and no feature is added twice. C<ALL ALL ALL> is the same as just
C<ALL>.
Since labels can only be specified in upper case for the C<evaluate> method,
they are matched case-insensitive.

The second argument is C<normal>, C<numeric> or C<binary>. C<normal> means that
the features' return values should be left alone (but postprocessed if such
option is set). C<numeric> and C<binary> mean that the features' return values
should be converted into numbers or binary vectors, as for support vector
machines or neural networks to like them.

The return value is the list of what the features returned. In case of binary,
there can be a
different (typically greater) number of elements in the returned list than there
were features to evaluate.

During evaluation, the features can access the
C<$Data::FeatureFactory::CURRENT_FEATURE> variable, which holds the name of the
feature evaluated.

=head3 Transfer to numeric / binary form

When you have the features output in numeric format, then integer and numeric
features are left alone and categorial ones have a natural number (starting with
1) assigned to every distinct value. If you use this feature, it is highly
recommended to specify the values for the feature. If you don't then
Data::FeatureFactory will attempt to create a mapping from the categories to numbers
dynamically as then feature is evaluated. The mapping is being saved to a file
whose name is C<.FeatureFactory.I<package_name>__I<feature_name>> and is located
in the directory where Data::FeatureFactory resides if possible, or in your home
directory or in /tmp - wherever the script can write. If none works, then you
get a fatal error. The mapping is restored and extended upon subsequent runs
with the same package and feature name, if read/write permissions don't change.

Binary format is such that the return value is converted to a vector of all 0's
and one 1. The positions in the vector represent the possible values of the
feature and 1 is on the position that the feature actually has in that
particular case. The values always need to be specified for this feature to work
and it is highly recommended that they be specified with a fixed order (not by a
hash), because else the order can change with different versions of perl and
when you change the set of values for the feature. And when the order changes,
then the meaning of the vectors change.

=head2 N/A values

You can specify a value to be substituted when a feature returns nothing (an
undefined value). This is passed as an argument to the C<new> method.

 $f = MyFeatures->new({ 'N/A' => '_' }); # MyFeatures inherits from Data::FeatureFactory
 $v = $f->evaluate('feature1', 'normal', 'unexpected_argument');

If C<feature1> returns an undefined value, then $v will contain the string '_'.
When evaluating in binary format, a vector of the usual length is returned, with
all values being the specified N/A. That is, if C<feature1> has 3 possible
values, then

 @v = $f->evaluate('feature1', 'binary', 'unexpected_argument');

will result in @v being C<('_', '_', '_')>. If C<feature1> returns undef, that
is.

N/A values don't get postprocessed in case a postprocessing function is
specified.

=head2 Conversion between formats

Once you evaluate the features on a million observations and save it in a file,
you might want to get the values in another format without having to evaluate
the features all over again (which can be time consuming). This is where the
method C<translate> comes in handy.

C<translate> accepts three arguments: Source filehandle, destination filehandle
and a hash with options (some of which aren't actually optional). The options
are:

=over 4

=item from_format

=item to_format

C<normal>, C<numeric> or C<binary>.

=item names

The names of the features that are in the source file, in order. This can be
anything that the C<evaluate> method accepts: An arrayref with the actual names
of the features present, or a label expression (see L<Evaluating features>).

=item header

If the names of the features are in the first line of the source file, don't
specify the C<names> option but set the C<header> option to a true value
instead.

The names of the features in the header shall be separated with the same string
that separates the values on the following lines. There can be any number of
separators between the feature names and Data::FeatureFactory will treat
C<name1,name2> exactly the same as C<name1,,,name2> (assuming you use comma as
separator). This only applies in the header and has a reason:

When the header is in the source file, then it's translated to the output as
well. And since in the binary format, the features span usually more than one
column, Data::FeatureFactory::translate will put so many separators after each
feature name as there are columns to its value. This is so you need not use the
module to figure out how many digits each feature has. For example, if you have
feature C<feat1> with three possible values, then its name in the header will be
followed by three separators: C<feat1,,,feat2>.

When reading the header, this is discarded because 1) You may want to write the
header yourself or use one from a non-binary version and 2) Data::FeatureFactory
has all information it needs in the @features array.

=item FS

The field separator that delimits the values in the files.

=item OFS

The output field separator: If you want the values separated with a different
character / string in the destination file than in the source file, then this is
the option to use.

=item from_NA

=item to_NA

The value specified for C<from_NA> is interpreted as denoting the N/A values in
the source file. These values will be converted to C<to_NA> in the destination
file. If the C<Data::FeatureFactory> object has the N/A option specified, then
that value is assumed for any of these two options implicitly.

=back

Required options are: from_format, to_format, FS and either names or header.

Note that when translating a categorial feature without values specified to/from
numeric format, then the dynamic mapping of values created by
C<Data::FeatureFactory> must get resumed successfully. Otherwise you'll get an
error about unexpected value as soon as the translation is attempted.

=head3 Translating rows (not files)

There's also a lower-level method available: C<translate_row>. Unlike the
C<translate> method, it doesn't accept filehandles but accepts an arrayref with
values and returns an array with the translated values. The arguments are:

=over 4

=item names

This time a required argument, same as the C<names> option to C<translate>.

=item values

The arrayref of values to convert.

=item options

Same as with the C<translate> method, except the C<names> and C<header> options
are not accepted.

=back

This method has the slight difference over C<translate> (beside only translating
one row per call) that if the C<to_NA> option is specified but neither
C<from_NA> option to the method nor the C<N/A> option to the object are
specified, then undef's are interpreted as N/A values.

=head2 Other low-level methods

There are some other subroutines defined in C<Data::FeatureFactory>. One of
those that might be of use to you is the C<expand_names> method, which you can
give a label expression as an argument and it will give you the list of feature
names that this label expression represents. For a description of how labels
work, see L<Evaluating features>.

=head1 COPYRIGHT

Copyright (c) 2008 Oldrich Kruza. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
