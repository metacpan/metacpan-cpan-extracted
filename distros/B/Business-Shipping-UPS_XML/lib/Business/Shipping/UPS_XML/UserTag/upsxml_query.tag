UserTag  upsxml-query  Order  service_code origin zip weight country
UserTag  upsxml-query  addAttr
UserTag  upsxml-query  Routine <<EOR
sub {
   ################################################################################
   #
   #  Script Name : upsxml_query.tag
   #  Version     : 1
   #  Company     : Down Home Web Design, Inc
   #  Author      : Duane Hinkley ( duane@dhwd.com )
   #  Website     : www.DownHomeWebDesign.com
   #
   #  Description: Uses the custom UPSXML module to calculate shipping between
   #               countries.  Specialy works for Canada to Canada and/or other
   #               countries.
   #               
   #  Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.
   #
   #  $Header: /home/cvs/interchange_upsxml/lib/Business/Shipping/UPS_XML/UserTag/upsxml_query.tag,v 1.2 2004/06/27 14:53:32 dlhinkley Exp $
   #
   #  $Log: upsxml_query.tag,v $
   #  Revision 1.2  2004/06/27 14:53:32  dlhinkley
   #  Cleaning up for realease
   #
   #  Revision 1.1  2004/06/27 13:53:20  dlhinkley
   #  Rename module to UPS_XML
   #
   #  Revision 1.5  2004/06/16 00:52:45  dlhinkley
   #  Clean up docs and add capability of multiple quantity of packages
   #
   #  Revision 1.4  2004/06/15 14:56:34  dlhinkley
   #  Added sending dimensions for multiple packages
   #
   #  Revision 1.3  2004/06/10 02:03:16  dlhinkley
   #  Fixed bugs from breaking up code and putting in CPAN format
   #
   #  Revision 1.2  2004/06/01 02:48:25  dlhinkley
   #  Changes to make work
   #
   #  Revision 1.1  2004/06/01 02:11:33  dlhinkley
   #  Convert to format usable by CPAN
   #
   #  Revision 1.6  2004/05/21 21:28:36  dlhinkley
   #  Add Currency
   #
   #  Revision 1.5  2004/04/20 03:24:11  dlhinkley
   #  Remove debuging error message
   #
   #  Revision 1.4  2004/04/20 01:28:01  dlhinkley
   #  Added option for dimensions
   #
   #  Revision 1.3  2004/03/14 18:50:31  dlhinkley
   #  Working version
   #
   #
   ################################################################################

 	my( $service_code, $origin, $zip, $weight, $country, $opt) = @_;
	$opt ||= {};

	use Business::Shipping::UPS_XML;

	my $userid		= $::Variable->{UPSXML_USERID};
	my $userid_pass		= $::Variable->{UPSXML_PASSWORD};
	my $access_key		= $::Variable->{UPSXML_ACCESS_KEY};
	my $origin_country	= $::Variable->{UPSXML_ORIGIN_COUNTRY};
	my $origin_zip		= $::Variable->{XMLUPS_ORIGIN};
	$origin_zip			||= $::Variable->{UPSXML_ORIGIN};
	my $dim_from_db		= $::Variable->{UPSXML_DBDIM};
	my $unit_of_measure = $::Variable->{UPSXML_DIMUNIT};

        my $ups = new Business::Shipping::UPS_XML($userid,$userid_pass,$access_key,$origin_country);

	$origin		||= $::Variable->{XMLUPS_ORIGIN};
	$origin		||= $::Variable->{UPSXML_ORIGIN};
	$country	||= $::Values->{$::Variable->{UPS_COUNTRY_FIELD}};
	$zip		||= $::Values->{$::Variable->{UPS_POSTCODE_FIELD}};

	my $modulo = $opt->{aggregate};

	if($modulo and $modulo < 10) {
		$modulo = $::Variable->{UPS_QUERY_MODULO} || 150;
	}
	elsif(! $modulo) {
		$modulo = 9999999;
	}

	$country = uc $country;

    # if the default zip is not a US zip, set it to a US zip if US is the country
	#
	if ($country eq 'US' ) {
		
		#if ( ! $zip =~ m/^\d{5}/ ) {

		    $zip = $::Variable->{UPS_US_DEFAULT};
		#}
		# In the U.S., UPS only wants the 5-digit base ZIP code, not ZIP+4
		#
		$zip =~ /^(\d{5})/ and $zip = $1;
	}

	# In the Canada, UPS doesn't want the spaces
	$country eq 'CA' and $zip =~ s/ //g;

	my $cache;
	my $cache_code;
	my $db;
	my $now;
	my $updated;
	my %cline;
	my $shipping;
	my $zone;
	my $error;

	# This cache section is untested and will definatly not work accuratly for packages with dimensions
	#
	my $ctable = $opt->{cache_table} || 'ups_cache';

	if( $Vend::Database{$ctable} && ! $dim_from_db && ! $opt->{'width'} ) {
		$Vend::WriteDatabase{$ctable} = 1;
		CACHE: {
			$db = dbref($ctable)
				or last CACHE;
			my $tname = $db->name();
			$cache = 1;
			%cline = (
				weight => $weight,
				origin => $origin,
				country => $country,
				zip	=> $zip,
				shipmode => $service_code,
			);

			my @items;
			# reverse sort makes zip first
			for(reverse sort keys %cline) {
				push @items, "$_ = " . $db->quote($cline{$_}, $_);
			}

			my $string = join " AND ", @items;
			my $q = qq{SELECT code,cost,updated from $tname WHERE $string};
			my $ary = $db->query($q);
			if($ary and $ary->[0] and $cache_code = $ary->[0][0]) {
				$shipping = $ary->[0][1];
				$updated = $ary->[0][2];
				$now = time();
				if($now - $updated > 86000) {
					undef $shipping;
					$updated = $now;
				}
				elsif($shipping <= 0) {
					$error = $shipping;
					$shipping = 0;
				}
			}
		}
	}

	my $w = $weight;
	my $maxcost;
	my $tmpcost;
	my $currency;

	# Dimensions are available and provided in the products db fields length, width, height, unit_of_measure
	#
    if ( $dim_from_db ) {

	    my $pdb = ::database_exists_ref('products');
        my $cart = $Carts->{main};
    
       foreach my $item (@$cart){

           my $sql = "SELECT length, width, height, weight FROM products WHERE sku = '" . $item->{code} . "'";
::logDebug("getUPS Dimensions query: $sql");

		   my $pary		= $pdb->query($sql);
		   my $length	= $pary->[0][0];
		   my $width	= $pary->[0][1];
		   my $height	= $pary->[0][2];
		   my $weight	= $pary->[0][3];

		   if ( ! $weight ) {

			   $weight = 1;
		   }

           # If there's more than one item, loop through several times.
		   # Otherwise, just loop through once.
		   #
		   for (my $l = 1; $l <= $item->{quantity} ;$l++) {

              $ups->set_dimensions( $length, $width, $height, $unit_of_measure, $weight );
::logDebug("getUPS Dimensions Set: $length, $width, $height, $unit_of_measure, $weight");
		   }
	   }

    }
	elsif ( $opt->{'width'} && $opt->{'height'} && $opt->{'length'} && $opt->{'unit_of_measure'} ) {

       # Dimensions are optional.  If the dimensions are undefined, the class will ignore 
	   #
       $ups->set_dimensions( $opt->{'width'}, $opt->{'height'}, $opt->{'length'}, $opt->{'unit_of_measure'}, $weight );
	}

	unless(defined $shipping) {
		$shipping = 0;
		while($w > $modulo) {
			$w -= $modulo;
			if($maxcost) {
				$shipping += $maxcost;
				next;
			}

			($maxcost, $zone, $error,$currency) = $ups->getUPS( $service_code, $origin_zip, $zip, $country, $modulo);
::logDebug("getUPS Send XML: \n" . $ups->send_xml() );
::logDebug("getUPS Receive XML: \n" . $ups->rcv_xml() );
#::logDebug("getUPS Passed: $service_code, $origin_zip, $zip, $country, $modulo, $currency");
            $::Variable->{currency} = $currency;

			if($error) {
				$Vend::Session->{ship_message} .= " $service_code: $error";
				return 0;
			}
			$shipping += $maxcost;
		}

		undef $error;
		($tmpcost, $zone, $error,$currency) = $ups->getUPS( $service_code, $origin_zip, $zip, $country, $w);
::logDebug("getUPS Send XML: \n" . $ups->send_xml() );
::logDebug("getUPS Receive XML: \n" . $ups->rcv_xml() );
#::logDebug("getUPS Passed: $service_code, $origin_zip, $zip, $country, $w, $currency");
            $::Variable->{currency} = $currency;

		$shipping += $tmpcost;
		if($cache) {
			$cline{updated} = $now || time();
			$cline{cost} = $shipping || $error;
			$db->set_slice($cache_code, \%cline);
		}
	}

	if($error) {
		$Vend::Session->{ship_message} .= " $service_code: $error";
		return 0;
	}
	return $shipping;
}
EOR

UserTag  upsxml-query  Documentation <<EOD

=head1 NAME

upsxml-query tag -- calculate UPS costs via www

=head1 SYNOPSIS

  [upsxml-query
     weight=NNN
     origin=45056*
     zip=61821*
     country=US*
     service_code=SERVICE_CODE
     aggregate=N*
  ]
	
=head1 DESCRIPTION

Calculates UPS costs via the WWW using Business::UPS.

Options:

=over 4

=item weight

Weight in pounds. (required)

=item service_code

Any valid Business::UPS service_code (required). Example: 12, 10, 03

=item origin

Origin zip code. Default is $Variable->{UPS_ORIGION}.

=item zip

Destination zip code. Default $Values->{zip}.

=item country

Destination country. Default $Values->{country}.

=item aggregate

If 1, aggregates by a call to weight=150 (or $Variable->{UPS_QUERY_MODULO}).
Multiplies that times number necessary, then runs a call for the
remainder. In other words:

	[upsxml-query weight=400 service_code=13 aggregate=1]

is equivalent to:

	[calc]
		[upsxml-query weight=150 service_code=03  length=36 width=10 height=10 unit_of_measure=IN ] + 
		[upsxml-query weight=150 service_code=03] + 
		[upsxml-query weight=100 service_code=03];
	[/calc]

If set to a number above 10, will be the modulo to do repeated calls by. So:

	[upsxml-query weight=400 service_code=03 aggregate=100]

is equivalent to:

	[calc]
		[upsxml-query weight=100 service_code=03] + 
		[upsxml-query weight=100 service_code=03] + 
		[upsxml-query weight=100 service_code=03] + 
		[upsxml-query weight=100 service_code=03];
	[/calc]

=item cache_table

Set to the name of a table (default ups_cache) which can cache the
calls so repeated calls for the same values will not require repeated
calls to UPS.

Table needs to be set up with:

	Database   ups_cache        ship/ups_cache.txt         __SQLDSN__
	Database   ups_cache        AUTO_SEQUENCE  ups_cache_seq
	Database   ups_cache        DEFAULT_TYPE varchar(12)
	Database   ups_cache        INDEX  weight origin zip shipmode country

And have the fields:

	 code weight origin zip country shipmode cost updated

Typical cached data will be like:

	code	weight	origin	zip	country	shipmode	cost	updated
	14	11	45056	99501	US	2DA	35.14	1052704130
	15	11	45056	99501	US	1DA	57.78	1052704130
	16	11	45056	99501	US	2DA	35.14	1052704132
	17	11	45056	99501	US	1DA	57.78	1052704133

Cache expires in one day.

=back

EOD
