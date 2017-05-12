#! /usr/bin/perl -w

use lib './ARS';
use ARS::CodeTemplate;

ARS::CodeTemplate::init_template();


#--- EDIT HERE ---

require 'StructDef.pl';

( $H_File, $C_File ) = ( 'supportrev_generated.h', 'supportrev_generated.c' );

@classes_H = ( sort keys %CONVERT, 'ARQualifierStruct' );
@classes_C = ( sort keys %CONVERT );

# @classes_H = @classes_C = qw();

$LINE_INDENT = '';

#--- END EDIT ---


$ARS::CodeTemplate::TPT_CODE = <<'#--- END TEMPLATE ---';
@>
@>#--- BEGIN TEMPLATE ---

#ifndef __supportrev_generated_h_
#define __supportrev_generated_h_

#undef EXTERN
#ifndef __supportrev_generated_c_
# define EXTERN extern
#else
# define EXTERN 
#endif

#include "ar.h"
#include "arstruct.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include <limits.h>


@> foreach my $class ( @classes_H ){
@>     my $obj = $CONVERT{$class};
<@ versionIf($obj) @>
@>     unless( $obj->{_typedef} ){
@># EXTERN SV *perl_<@ $class @>( ARControlStruct *ctrl, <@ $class @> *p );
@>         if( $obj->{_typeparam} ){
EXTERN int rev_<@ $class @>( ARControlStruct *ctrl, HV *h, char *k, char *t, <@ $class @> *p );
@>         }else{
EXTERN int rev_<@ $class @>( ARControlStruct *ctrl, HV *h, char *k, <@ $class @> *p );
@>         }
@>     }
<@ versionEndif($obj) @>
@> }

void copyIntArray( int size, int *dst, SV* src );
void copyUIntArray( int size, ARInternalId *dst, SV* src );

#endif /* __supportrev_generated_h_ */

@@ > <@ $H_File @>


#define __supportrev_generated_c_

#include "<@ $H_File @>"
#include "supportrev.h"
#include "support.h"


#if defined(ARSPERL_UNDEF_MALLOC) && defined(malloc)
 #undef malloc
 #undef calloc
 #undef realloc
 #undef free
#endif


@> foreach my $class ( @classes_C ){
@>     my $obj = $CONVERT{$class};
@>
@>     if( $obj->{_typedef} || $obj->{_header_only} ){
@>         next;
@>     }
@>

@># SV *
@># perl_<@ $class @>( ARControlStruct *ctrl, <@ $class @> *p ){
@># 	SV *ret;
@># @>     structToPerl( $obj, "\t" );
@># 	return ret;
@># }

<@ versionIf($obj) @>
@>     if( $obj->{_typeparam} ){
int
rev_<@ $class @>( ARControlStruct *ctrl, HV *h, char *k, char *t, <@ $class @> *p ){
@>     }else{
int
rev_<@ $class @>( ARControlStruct *ctrl, HV *h, char *k, <@ $class @> *p ){
@>     }
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){
@>     if( $obj->{_typeparam} ){
		// printf( "<@ $class @>: t = <%s>\n", t );
		if( hv_exists(h,t,strlen(t)) ){
			SV **type;
			char *pcase;
			type = hv_fetch( h, t, strlen(t), 0 );

			if( type && *type ){
				pcase = SvPV_nolen(*type);
@>         if( $obj->{_map} ){
				<@ $obj->{_switch} @> = caseLookUpTypeNumber( (TypeMapStruct*) <@ $obj->{_map} @>, pcase );
@>         }else{
				<@ $obj->{_switch} @> = 0;
@>             foreach my $key ( keys %{$obj->{_case}} ){
@>                 my( $pcase, $dummy ) = each %{$obj->{_case}{$key}};
				if( !strcmp(pcase,"<@ $pcase @>") )  <@ $obj->{_switch} @> = <@ $key @>;
@>             }
@>         }
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_<@ $class @>: hv_fetch (type) returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_<@ $class @>: key (type) doesn't exist");
			return -2;
		}
@>     }

		// printf( "<@ $class @>: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
@>     perlToStruct( $obj, $class, "\t\t\t\t" );
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_<@ $class @>: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_<@ $class @>: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: first argument is not a hash");
		return -1;
	}

	return 0;
}
<@ versionEndif($obj) @>
@> }



@> sub perlToStruct {
@>     my( $obj, $class, $LINE_INDENT ) = @_;
{
@>     if( $obj->{_data} ){
@>         my( $type, $data ) = ( $obj->{_type}, $obj->{_data} );
@>             if( $obj->{_map} ){
	int flag = 0;
@>                 foreach my $key ( keys %{$obj->{_map}} ){
	if( !strcmp(SvPV_nolen(*val),"<@ $obj->{_map}{$key} @>") ){
		<@ $obj->{_data} @> = <@ $key @>;
		flag = 1;
	}
@>                 }
	if( flag == 0 ){
		ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_<@ $class @>: invalid key value" );
		ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
	}
@>             }else{
	<@ typeCopy($type,$data,'*val') @>;
@>             }
@>     }
@>     if( $obj->{_switch} ){

	{
		char *pcase = NULL;
		char errText[512];

@>         if( $obj->{_map} && !ref($obj->{_map}) ){
			// pcase = SvPV_nolen(*val);
			// <@ $obj->{_switch} @> = caseLookUpTypeNumber( (TypeMapStruct*) <@ $obj->{_map} @>, pcase );
@>             if( ! $obj->{_typeparam} ){
			HV *h2 = (HV* ) SvRV((SV*) *val);
			SV** val = hv_fetch( h2, "<@ $obj->{_map} @>", <@ length($obj->{_map}) @>, 0 );
			<@ $obj->{_switch} @> = SvIV(*val);
@>             }
@>         }else{
		HV *h;
		SV **hval = NULL;
		char *k   = NULL;
		if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
			ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: not a hash value" );
			return -1;
		}
		h = (HV* ) SvRV((SV*) *val);

@>             if( $obj->{_map} && ref($obj->{_map}) eq 'ARRAY' ){
@>                 my( $switchKey, $hMap ) = @{$obj->{_map}};
@>                 my @nonNum = grep {/\D/} values %$hMap;
		hval = hv_fetch( h, "<@ $switchKey @>", <@ length($switchKey) @>, 0 );

			if( hval && *hval ){
				pcase = SvPV_nolen(*hval);
				if( 0 ){
@>                 foreach my $key ( sort keys %$hMap ){
<@ versionIf($obj->{_case}{$key}) @>
@>                     if( @nonNum ){
				}else if( !strcmp(pcase,"<@ $hMap->{$key} @>") ){
@>                     }else{
				}else if( SvIV(*hval) == <@ $hMap->{$key} @> ){
@>                     }
					<@ $obj->{_switch} @> = <@ $key @>;                 
<@ versionEndif($obj->{_case}{$key}) @>
@>                 }
				}else{
					ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_<@ $class @>: key doesn't exist");
					ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, pcase );
					return -2;
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_<@ $class @>: hv_fetch (hval) returned null");
				return -2;
			}
@>             }else{
			if( 0 ){
@>                 foreach my $key ( keyFilter($obj->{_case},'_data') ){
@>                     # my( $pcase, $dummy ) = each %{$obj->{_case}{$key}};
@>                     my( $pcase ) = grep {!/^_/} keys %{$obj->{_case}{$key}};
@>                     my $key2 = $key;
@>                     $key2 =~ s/\W+$//;
<@ versionIf($obj->{_case}{$key}) @>
			}else if( hv_exists(h,"<@ $pcase @>",<@ length($pcase) @>) ){
				<@ $obj->{_switch} @> = <@ $key2 @>;
				k = "<@ $pcase @>";
<@ versionEndif($obj->{_case}{$key}) @>
@>                 }
@>                 foreach my $key ( keyFilter($obj->{_case},'_default') ){
			}else if( 1 ){
			    <@ $obj->{_switch} @> = <@ $key @>;
@>                 }
			}else{
			    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: map error" );
			}
@>             }
@>         }


			switch( <@ $obj->{_switch} @> ){
@>         foreach my $key ( keyFilter($obj->{_case},'_data') ){
@>             my $key2 = $key;
@>             $key2 =~ s/\W+$//;
@>             my $type = $obj->{_case}{$key}{_type};
@>             my $data = $obj->{_case}{$key}{_data};
<@ versionIf($obj->{_case}{$key}) @>
			case <@ $key2 @>:
@>             perlToStruct( $obj->{_case}{$key}, $class, "$LINE_INDENT\t\t\t\t" );
				break;
<@ versionEndif($obj->{_case}{$key}) @>
@>         }
@>         foreach my $key ( keyFilter($obj->{_case},'_default','_nodata') ){
			case <@ $key @>:
				break;
@>         }
			default:
				sprintf( errText, "rev_<@ $class @>: invalid switch value %d", <@ $obj->{_switch} @> );
				ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
			}

	}

@>     }
@>     if( $obj->{_list} ){
@>         my( $type, $data ) = ( $obj->{_type}, $obj->{_list}.'[i]' );
	{
		if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
			int i = 0, num = 0;
			AV *ar = (AV*) SvRV((SV*) *val);

			num = av_len(ar) + 1;
			<@ $obj->{_num}  @> = num;
			if( num == 0 ) return 0;

@>         unless( $type =~ s/\[\]// ){
			<@ $obj->{_list} @> = (<@ $type @>*) MALLOCNN( sizeof(<@ $type @>) * num );
			/* if( <@ $obj->{_list} @> == NULL ){
				croak( "rev_<@ $class @>: malloc error\n" );
				exit( 1 );
			} */
@>         }

			for( i = 0; i < num; ++i ){
				SV **item = av_fetch( ar, i, 0 );

				if( item && *item ){
					char *k = "_";
					HV *h = newHV();
					
					SvREFCNT_inc( *item );
                    hv_store( h, k, strlen(k), *item, 0 );

					<@ typeCopy($type,$data,'*item') @>;
					hv_undef( h );
				}else{
					ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: invalid inner array value" );
				}
			}
		}else{
			ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: hash value is not an array reference" );
			ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
			return -1;
		}
	}
@>     }
@>     if( grep {!/^_/} keys %$obj ){


	if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
		int i = 0, num = 0;
		HV *h = (HV* ) SvRV((SV*) *val);
		char k[256];
		k[255] = '\0';

@>         foreach my $key ( grep {!/^_/} keys %$obj ){
@>             my $key2 = $key;
@>             $key2 =~ s/\W+$//;
<@ versionIf($obj->{$key}) @>
	{
		SV **val;
		strncpy( k, "<@ $key2 @>", 255 );
		val = hv_fetch( h, "<@ $key2 @>", <@ length($key2) @>, 0 );
		if( val && *val && <@ ($obj->{$key}{_type} eq 'ARValueStruct')? '(SvOK(*val) || SvTYPE(*val) == SVt_NULL)' : 'SvOK(*val)' @> ){
@>             perlToStruct( $obj->{$key}, $class, "$LINE_INDENT\t\t\t" );
		}else{
@>             if( $obj->{$key}{_default} ){
			<@ $obj->{$key}{_data} @> = <@ $obj->{$key}{_default} @>;
@>             }else{
			ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"<@ $key2 @>\"" );
			return -1;
@>             }
		}
	}
<@ versionEndif($obj->{$key}) @>
@>         }

	}else{
		ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_<@ $class @>: hash value is not a hash reference" );
		return -1;
	}


@>     }
}
@> }


void copyIntArray( int size, int *dst, SV* src ){
	AV *ar = (AV*) SvRV((SV*) src);
	int len = av_len(ar);
	int i;
	for( i = 0; i < size; ++i ){
		dst[i] = 0;
		if( i <= len ){ 
			SV** item = av_fetch( ar, i, 0 );
			if( item != NULL && *item != NULL && i <= len ){
				dst[i] = (SvOK(*item))? SvIV(*item) : 0;
			}
		}
	}
}

void copyUIntArray( int size, ARInternalId *dst, SV* src ){
	AV *ar = (AV*) SvRV((SV*) src);
	int len = av_len(ar);
	int i;
	for( i = 0; i < size; ++i ){
		dst[i] = 0;
		if( i <= len ){ 
			SV** item = av_fetch( ar, i, 0 );
			if( item != NULL && *item != NULL && i <= len ){
				dst[i] = (SvOK(*item))? SvUV(*item) : 0;
			}
		}
	}
}



@@ > <@ $C_File @>




@> foreach my $class ( @classes_C ){
@>     my $obj = $CONVERT{$class};
@>     if( $obj->{_typedef} || $obj->{_header_only} ){
@>         next;
@>     }

SV *
perl_<@ $class @>( ARControlStruct *ctrl, <@ $class @> *p ){
	SV *ret;
@>     structToPerl( $obj, "\t" );
	return ret;
}
@> }



@> sub structToPerl {
@>     my( $obj, $LINE_INDENT ) = @_;
{
@>     if( $obj->{_data} ){
@>         my( $type, $data ) = ( $obj->{_type}, $obj->{_data} );
	SV *val;
	<@ perlCopy($type,'val',$data) @>;
	ret = val;
@>     }elsif( $obj->{_switch} ){
	SV *val;

	switch( <@ $obj->{_switch} @> ){
@>         foreach my $key ( keys %{$obj->{_case}} ){
	case <@ $key @>:
@>		structToPerl( $obj->{_case}{$key}, "$LINE_INDENT\t" );
		break;
@>         }
	default:
		ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "<@ $class @>: Invalid case" );
		break;
	}

	ret = val;
@>     }elsif( $obj->{_list} ){
@>         my( $type, $data ) = ( $obj->{_type}, $obj->{_list}.'[i]' );
	AV *array;
	SV *val;
	I32 i;

	array = newAV();
	av_extend( array, <@ $obj->{_num} @>-1 );

	for( i = 0; i < <@ $obj->{_num} @>; ++i ){
		<@ perlCopy($type,'val',$data) @>;
		av_store( array, i, val );
	}

	ret = newRV_noinc((SV *) array);
@>     }else{
	HV *hash;
	SV *val;

	hash = newHV();

@>         foreach my $key ( keys %$obj ){
@>             structToPerl( $obj->{$key}, "$LINE_INDENT\t" );
	hv_store( hash, "<@ $key @>", <@ length($key) @>, ret, 0 );

@>         }
	ret = newRV_noinc((SV *) hash);
@>     }
}
@> }

@@ > support_generated.c



#--- END TEMPLATE ---



$ARS::CodeTemplate::DEF_CODE = ARS::CodeTemplate::compile( $ARS::CodeTemplate::TPT_CODE );
ARS::CodeTemplate::procdef( $ARS::CodeTemplate::DEF_CODE );

#use UTAN::Util;
#UTAN::Util::modFileByRegex( 'functions.c', 's/^(\s*)rev_ARQualifierStruct\(.*/$1p->qualifier.operation = AR_OPERATION_NONE;/' );


#--- EDIT HERE ---

sub evalTemplate {
	my( $tag, $type, $L, $R ) = @_;
#	print STDERR "evalTemplate( $tag, $type, $L, $R )\n";  # _DEBUG_
	$tag = lc($tag);
	$tag =~ s/^(?=[^_])/_/;

	my( $tpDef, $tp ) = ( $TEMPLATES{$tag} );
	if( !defined $tpDef ){
		die "NO TEMPLATE GROUP\n", "\$tag <$tag>  \$type <$type>  \$L <$L>  \$R <$R>\n";  # _DEBUG_
#		exit 1;
	}

#	foreach my $rx ( keys %$tpDef ){
#		if( $type =~ /^$rx$/ ){
#			$tp = $tpDef->{$rx};
#			last;
#		}
	my @match;
	for( my $i = 0; $i < $#{$tpDef}; $i+=2 ){
		$rx = $tpDef->[$i];
#		print "\$rx <$rx>\n";  # _DEBUG_
		@match = ($type =~ /^$rx$/);
		if( @match ){
			unshift @match, 1 if $rx =~ /(?<!\\)\(/;
			$tp = $tpDef->[$i+1];
			last;
		}
	}
	if( !defined $tp ){
		die "NO TEMPLATE\n", "\$tag <$tag>  \$type <$type>  \$L <$L>  \$R <$R>\n";  # _DEBUG_
#		exit 1;
	}
#	print STDERR "\$tp <", $tp, ">\n";  # _DEBUG_

	my $baseType = $type;
	$baseType =~ s/\*$//;

	my %val = ( L => $L, R => $R, T => $type, B => $baseType );
	map {$val{$_} = $match[$_]} (1..$#match) if $#match >= 1;
#	print "\$rx <", $rx, ">  \@match <", join('|',@match), ">  \%val <", join('|',%val), ">\n";  # _DEBUG_
	$tp =~ s/\%([LRTB0-9])\b/$val{$1}/g;

	return $tp;
}

sub typeCopy {
	my( $type, $L, $R ) = @_;
	$type = $CONVERT{$type}{_typedef} while defined $CONVERT{$type}{_typedef};
	my $str = evalTemplate( '_copy', $type, $L, $R );
	return $str;
}

sub perlCopy {
	my( $type, $L, $R ) = @_;
	$type = $CONVERT{$type}{_typedef} while defined $CONVERT{$type}{_typedef};
	my $str = evalTemplate( '_perl', $type, $L, $R );
	return $str;
}

sub keyFilter {
	my( $hRef, @fkey ) = @_;
	my @list;
	foreach my $fkey ( @fkey ){
		foreach my $key ( keys %$hRef ){
			push @list, $key if findSubKey($hRef->{$key},$fkey);
		}
	}
#	print STDERR "\@list <", join('|',@list), ">\n";  # _DEBUG_
	return @list;
}

sub findSubKey {
	my( $hRef, $fkey ) = @_;
	my $ret = 0;
	if( ref($hRef) eq 'HASH' ){
		foreach my $key ( keys %$hRef ){
			if( $key eq $fkey ){
				$ret = 1;
			}else{
				$ret = findSubKey( $hRef->{$key}, $fkey );
			}
			last if $ret == 1;
		}
	}
	return $ret;
}

sub versionIf {
	my( $obj ) = @_;
	if( $obj->{_min_version} && $obj->{_max_version} ){
		return '#if AR_CURRENT_API_VERSION >= '. $CURRENT_API_VERSION{$obj->{_min_version}} .' && AR_CURRENT_API_VERSION <= '. $CURRENT_API_VERSION{$obj->{_max_version}};
	}elsif( $obj->{_min_version} ){
		return '#if AR_CURRENT_API_VERSION >= ' . $CURRENT_API_VERSION{$obj->{_min_version}};
	}elsif( $obj->{_max_version} ){
		return '#if AR_CURRENT_API_VERSION <= ' . $CURRENT_API_VERSION{$obj->{_max_version}};
	}else{
		return '';
	}
}

sub versionEndif {
	my( $obj ) = @_;
	if( $obj->{_min_version} || $obj->{_max_version} ){
		return '#endif';
	}else{
		return '';
	}
}






#--- END EDIT ---


