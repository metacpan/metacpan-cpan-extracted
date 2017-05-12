;<?/*
;#########################################################
;#         SNMPTraps-Frontend for Nagios & ASNMTAP       #
;#                                                       #
;#                    by Michael Lübben                  #
;#                   --- Lizenz GPL ---                  #
;#########################################################

[global]
;# Select here a language (EN = English / DE = German)
language = EN

;# When you will use a authentification, then enable this option  (0=off / 1=on)
useAuthentification = 1

;# If you use the authentification, then entry here the User that 
;# may changes on the Web-Frontend comma seperated.
allowedUser = ape,yvdh,snmptt

;# If you use the authentification, then entry here the User that may 'mark as read' 
;# or 'Delete this trap' on the Web-Frontend comma seperated.
allowedAction = ape,yvdh

;# Ignore this option, when you don`t use a table for archiving the Traps and/or 
;# unknown-Traps in your database
tableArchive = _archive

;# When you use a database for unknown-Traps, then enable this option (0=off / 1=on)
;# If you enable this option, then you musst have a table in your database for unknown
;# traps.
useUnknownTraps = 1

;# Entry here the number of traps, that you will see per side.
step = 30

;# Path to Image-Directory from your SNMP-Trap Frontend installation
images = ./images/

;# Select Icons for the Frontend (nuovo, kde3, nuvola_1 or nuvola_2)
iconStyle = kde3

;# Set here the Trap Message indicates to be cut off is after many indications.
;# When set no parameter, the Trap-Messages wasn't cut.  
cutTrapMessage = 100

;# Set here illegal charactars for output of the javabox
illegalCharJavabox = <,>,'


[nagios]
;# Url to Nagios
prefix = /asnmtap/snmptraps

;# Path to the Image-Dirctory from your Nagios-Installation
images = ../images/

;# Enter here your information that were used to connect to your database
[database]
host = dtbs.citap.be
user = asnmtap
password = <PASSWORD>
name = snmptt
tableSnmptt = snmptt

;# Ignore this option, when you don`t use a table for unknown-Traps in your database
tableSnmpttUnk = snmptt_unknown


;# ----------> DO NOT MAKE changes at this section! <----------
[internal]
;# Version
version = Version 0.1.1 Final

;# Title for the SNMP-Trap Frontend
title = SNMPTraps-Frontend

;*/?>
