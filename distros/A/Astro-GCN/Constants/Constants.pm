package Astro::GCN::Constants;

use strict;
use warnings;

use vars qw/ $VERSION @ISA %EXPORT_TAGS @EXPORT_OK/;
'$Revision: 1.1.1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

require Exporter;

@ISA = qw/Exporter/;

@EXPORT_OK = qw//;
                                      
%EXPORT_TAGS = ( 'packet_types'=>[qw/ TYPE_UNDEF	
                                      TYPE_GRB_COORDS
                                      TYPE_TEST_COORDS
                                      TYPE_IM_ALIVE
                                      TYPE_KILL_SOCKET
                                      TYPE_MAXBC
                                      TYPE_BRAD_COORDS
                                      TYPE_GRB_FINAL
                                      TYPE_HUNTS_SRC
                                      TYPE_ALEXIS_SRC
                                      TYPE_XTE_PCA_ALERT
                                      TYPE_XTE_PCA_SRC
                                      TYPE_XTE_ASM_ALERT
                                      TYPE_XTE_ASM_SRC
                                      TYPE_COMPTEL_SRC
                                      TYPE_IPN_RAW_SRC
                                      TYPE_IPN_SEG_SRC
                                      TYPE_SAX_WFC_ALERT
                                      TYPE_SAX_WFC_SRC
                                      TYPE_SAX_NFI_ALERT
                                      TYPE_SAX_NFI_SRC
                                      TYPE_XTE_ASM_TRANS
                                      TYPE_spare_SRC
                                      TYPE_IPN_POS_SRC
                                      TYPE_HETE_ALERT_SRC
                                      TYPE_HETE_UPDATE_SRC
                                      TYPE_HETE_FINAL_SRC
                                      TYPE_HETE_GNDANA_SRC
                                      TYPE_HETE_TEST
                                      TYPE_GRB_CNTRPART_SRC
                                      TYPE_INTEGRAL_POINTDIR_SRC
                                      TYPE_INTEGRAL_SPIACS_SRC
                                      TYPE_INTEGRAL_WAKEUP_SRC
                                      TYPE_INTEGRAL_REFINED_SRC
                                      TYPE_INTEGRAL_OFFLINE_SRC
                                      TYPE_MILAGRO_POS_SRC
                                      TYPE_KONUS_LC_SRC
                                      TYPE_SWIFT_BAT_GRB_ALERT_SRC
                                      TYPE_SWIFT_BAT_GRB_POS_ACK_SRC
                                      TYPE_SWIFT_BAT_GRB_POS_NACK_SRC
                                      TYPE_SWIFT_BAT_GRB_LC_SRC
                                      TYPE_SWIFT_SCALEDMAP_SRC
                                      TYPE_SWIFT_FOM_2OBSAT_SRC
                                      TYPE_SWIFT_FOSC_2OBSAT_SRC
                                      TYPE_SWIFT_XRT_POSITION_SRC
                                      TYPE_SWIFT_XRT_SPECTRUM_SRC
                                      TYPE_SWIFT_XRT_IMAGE_SRC
                                      TYPE_SWIFT_XRT_LC_SRC
                                      TYPE_SWIFT_XRT_CENTROID_SRC
                                      TYPE_SWIFT_UVOT_DBURST_SRC
                                      TYPE_SWIFT_UVOT_FCHART_SRC
                                      TYPE_SWIFT_FULL_DATA_INIT_SRC
                                      TYPE_SWIFT_FULL_DATA_UPDATE_SRC
                                      TYPE_SWIFT_BAT_GRB_LC_PROC_SRC
                                      TYPE_SWIFT_XRT_SPECTRUM_PROC_SRC
                                      TYPE_SWIFT_XRT_IMAGE_PROC_SRC
                                      TYPE_SWIFT_UVOT_DBURST_PROC_SRC
                                      TYPE_SWIFT_UVOT_FCHART_PROC_SRC
                                      TYPE_SWIFT_UVOT_POS_SRC
                                      TYPE_SWIFT_BAT_GRB_POS_TEST
                                      TYPE_SWIFT_POINTDIR_SRC /] );

Exporter::export_tags('packet_types');

# PACKET TYPES
# ============

# This packet type is undefined
use constant TYPE_UNDEF	=> 0;

# BATSE-Original Trigger coords packet
use constant TYPE_GRB_COORDS => 1;

# Test coords packet  
use constant TYPE_TEST_COORDS => 2;

# I'm_alive packet 
use constant TYPE_IM_ALIVE => 3;

# Kill a socket connection packet
use constant TYPE_KILL_SOCKET => 4; 

# MAXC1/BC packet 
use constant TYPE_MAXBC	=> 11;
  
# Special Test coords packet for BRADFORD  
use constant TYPE_BRAD_COORDS => 21;

# BATSE-Final coords packet
use constant TYPE_GRB_FINAL => 22;

# Huntsville LOCBURST GRB coords packet
use constant TYPE_HUNTS_SRC => 24;

# ALEXIS Transient coords packet  
use constant TYPE_ALEXIS_SRC => 25;

# XTE-PCA ToO Scheduled packet  
use constant TYPE_XTE_PCA_ALERT	=> 26;

# XTE-PCA GRB coords packet
use constant TYPE_XTE_PCA_SRC => 27;

# XTE-ASM Alert packet
use constant TYPE_XTE_ASM_ALERT => 28;  

# XTE-ASM GRB coords packet
use constant TYPE_XTE_ASM_SRC => 29;  

# COMPTEL GRB coords packet
use constant TYPE_COMPTEL_SRC => 30;  

# IPN_RAW GRB annulus coords packet
use constant TYPE_IPN_RAW_SRC => 31;  

# IPN_SEGment GRB annulus segment coords pkt
use constant TYPE_IPN_SEG_SRC  => 32;  

# SAX-WFC Alert packet
use constant TYPE_SAX_WFC_ALERT => 33;  

# SAX-WFC GRB coords packet
use constant TYPE_SAX_WFC_SRC => 34;  

# SAX-NFI Alert packet
use constant TYPE_SAX_NFI_ALERT => 35;  

# SAX-NFI GRB coords packet
use constant TYPE_SAX_NFI_SRC => 36;  

# XTE-ASM TRANSIENT coords packet
use constant TYPE_XTE_ASM_TRANS => 37;  

# spare
use constant TYPE_spare_SRC => 38;  

# IPN_POSition coords packet
use constant TYPE_IPN_POS_SRC => 39;  

# HETE S/C_Alert packet
use constant TYPE_HETE_ALERT_SRC => 40;  

# HETE S/C_Update packet
use constant TYPE_HETE_UPDATE_SRC => 41;  

# HETE S/C_Last packet
use constant TYPE_HETE_FINAL_SRC => 42;  

# HETE Ground Analysis packet
use constant TYPE_HETE_GNDANA_SRC => 43;  

# HETE Test packet
use constant TYPE_HETE_TEST => 44;  

# GRB Counterpart coords packet
use constant TYPE_GRB_CNTRPART_SRC => 45;  

# INTEGRAL Pointing Dir packet
use constant TYPE_INTEGRAL_POINTDIR_SRC => 51;  

# INTEGRAL SPIACS packet
use constant TYPE_INTEGRAL_SPIACS_SRC => 52;  

# INTEGRAL Wakeup packet
use constant TYPE_INTEGRAL_WAKEUP_SRC => 53;  

# INTEGRAL Refined packet
use constant TYPE_INTEGRAL_REFINED_SRC => 54;  

# INTEGRAL Offline packet
use constant TYPE_INTEGRAL_OFFLINE_SRC => 55;  

# MILAGRO Position message
use constant TYPE_MILAGRO_POS_SRC => 58;  

# KONUS Lightcurve message
use constant TYPE_KONUS_LC_SRC => 59;  

# SWIFT BAT GRB ALERT message
use constant TYPE_SWIFT_BAT_GRB_ALERT_SRC => 60;  

# SWIFT BAT GRB Position Acknowledge message
use constant TYPE_SWIFT_BAT_GRB_POS_ACK_SRC => 61;  

# SWIFT BAT GRB Position NOT Acknowledge message
use constant TYPE_SWIFT_BAT_GRB_POS_NACK_SRC => 62;  

# SWIFT BAT GRB Lightcurve message
use constant TYPE_SWIFT_BAT_GRB_LC_SRC => 63;  

# SWIFT BAT Scaled Map message
use constant TYPE_SWIFT_SCALEDMAP_SRC => 64; 

# SWIFT BAT FOM to Observe message
use constant TYPE_SWIFT_FOM_2OBSAT_SRC => 65;  

# SWIFT BAT S/C to Slew message
use constant TYPE_SWIFT_FOSC_2OBSAT_SRC => 66;
  
# SWIFT XRT Position message
use constant TYPE_SWIFT_XRT_POSITION_SRC => 67;
  
# SWIFT XRT Spectrum message
use constant TYPE_SWIFT_XRT_SPECTRUM_SRC => 68;
  
# SWIFT XRT Image message (aka postage stamp)
use constant TYPE_SWIFT_XRT_IMAGE_SRC => 69; 
 
# SWIFT XRT Lightcurve message (aka Prompt)
use constant TYPE_SWIFT_XRT_LC_SRC => 70;  

# SWIFT XRT Position NOT Ack message (Centroid Error)
use constant TYPE_SWIFT_XRT_CENTROID_SRC => 71; 
 
# SWIFT UVOT DarkBurst message (aka Neighbor)
use constant TYPE_SWIFT_UVOT_DBURST_SRC => 72;  

# SWIFT UVOT Finding Chart message
use constant TYPE_SWIFT_UVOT_FCHART_SRC => 73; 
 
# SWIFT Full Data Set Initial message
use constant TYPE_SWIFT_FULL_DATA_INIT_SRC => 74;  

# SWIFT Full Data Set Updated message
use constant TYPE_SWIFT_FULL_DATA_UPDATE_SRC => 75;
 
# SWIFT BAT GRB Lightcurve processed message
use constant TYPE_SWIFT_BAT_GRB_LC_PROC_SRC => 76; 
 
# SWIFT XRT Spectrum processed message
use constant TYPE_SWIFT_XRT_SPECTRUM_PROC_SRC => 77;  

# SWIFT XRT Image processed message
use constant TYPE_SWIFT_XRT_IMAGE_PROC_SRC => 78;  

# SWIFT UVOT DarkBurst processed mesg (aka Neighbor)
use constant TYPE_SWIFT_UVOT_DBURST_PROC_SRC => 79;  

# SWIFT UVOT Finding Chart processed message
use constant TYPE_SWIFT_UVOT_FCHART_PROC_SRC => 80;  

# SWIFT UVOT Position message
use constant TYPE_SWIFT_UVOT_POS_SRC  => 81;  

# SWIFT BAT GRB Position Test message
use constant TYPE_SWIFT_BAT_GRB_POS_TEST => 82; 
 
# SWIFT Pointing Direction message
use constant TYPE_SWIFT_POINTDIR_SRC => 83; 

1;
