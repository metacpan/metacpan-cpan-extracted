package DateTime::Format::Human::Duration::Locale;

# require DateTime::Format::Locale;

use strict;
use warnings;

sub calc_locale {
    my ($span, $loc) = @_;

    # DateTime::Format::Locale::
    my $final = determine_locale_from({
        'base_object'     => $span,
        'get_locale_from' => $loc,  
        'locale_ns_path'  => 'DateTime/Format/Human/Duration/Locale',  # DateTime::Format::Human::Duration::Locale
    });

    if ($final) {  
        return $final if ref $final; # returned 'locale_cache' we created below
             
        my $ns = "DateTime::Format::Human::Duration::Locale::$final";
        # get_human_span_from_units_array has been deprecated, but we'll
        # still support it.
        if ( $ns->can('get_human_span_from_units_array') ) {
            $span->{'locale_cache'}{ $final } = $ns;
        }
        elsif ( $ns->can('get_human_span_from_units') ) {
            $span->{'locale_cache'}{ $final } = $ns;
        }
        elsif ( my $sub = $ns->can('get_human_span_hashref') ) {
            $span->{'locale_cache'}{ $final } = $sub->();
        }
         
        if ( exists $span->{'locale_cache'}{ $final } ) {
            return $span->{'locale_cache'}{ $final };
        }
    }
    
    return '';
}

# DateTime::Format::Locale::
sub determine_locale_from {
    my ($args_hr) = @_;

    return '' if !$args_hr->{'get_locale_from'};

    if (ref $args_hr->{'get_locale_from'}) {
	my $locale_obj;
	if (UNIVERSAL::can($args_hr->{'get_locale_from'}, 'locale')) {
	    $locale_obj = $args_hr->{'get_locale_from'}->locale;
	}
	else {
	    $locale_obj = $args_hr->{'get_locale_from'};
	}

	if (UNIVERSAL::can($locale_obj, 'code')) {
	    $args_hr->{'get_locale_from'} = $locale_obj->code; # DateTime::Locale v1
	}
	elsif (UNIVERSAL::can($locale_obj, 'id')) {
	    $args_hr->{'get_locale_from'} = $locale_obj->id;   # DateTime::Locale v0
	}
	else {
	    my $ns = ref($args_hr->{'get_locale_from'});
	    ($args_hr->{'get_locale_from'}) = reverse split /::/, $ns;
	}
    }
    
    my ($short) = split(/[-_]+/,$args_hr->{'get_locale_from'});

    my $final = '';
    my @try = $args_hr->{'get_locale_from'} eq $short ? ($args_hr->{'get_locale_from'}) : ($args_hr->{'get_locale_from'}, $short);
    
    NS:
    for my $locale ( @try ) {
        if ( exists $args_hr->{'base_object'}{'locale_cache'}{ $locale } ) {
            if ( $args_hr->{'base_object'}{'locale_cache'}{ $locale } ) {
                return $locale;
            }
            else {
                next NS;
            }
        }
        
        $args_hr->{'locale_ns_path'} =~ s{/$}{};
        my $path = "$args_hr->{'locale_ns_path'}/$locale\.pm";
        
        if( exists $INC{$path} || eval { $args_hr->{'loads'}{$locale}++; require $path } ) {
            $final = $locale;  
            $args_hr->{'base_object'}{'locale_cache'}{ $locale } = 1;
            last NS;        
        }
        else {
            push @{$args_hr->{'errors'}{$locale}}, $@;
            $args_hr->{'base_object'}{'locale_cache'}{ $locale } = '';   
        }
    }
    
    return $final;
}

1;
