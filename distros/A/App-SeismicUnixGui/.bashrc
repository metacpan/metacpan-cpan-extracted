#! /bin/bash -f
#################################################################
#
#         .bashrc File
#
#         Initial Setup File for both Interactive and Noninteractive

# If not running interactive, don't do anything
[ -z "$PS1" ] && return

#--------------------------------------------
#         Set my favorite prompt
# historycommand user@hostname:workingdirectoryfullpath %
#--------------------------------------------
PS1="\! \u@\h:\w % "

#--------------------------------------------
#         Put in global defaults.
#--------------------------------------------
source /usr/local/admin/bashrc_local

#--------------------------------------------
#         Environment variables
#--------------------------------------------

#--------------------------------------------
#         Do not set prompt or aliases
#         if not an interactive shell
#--------------------------------------------

#if ( $?prompt ) then
#--------------------------------------------
#         Chdir shortcuts
#--------------------------------------------

#set cdpath  = ( ~ )

#--------------------------------------------
#         Aliases
#--------------------------------------------

#endif

#################################################################
# END OF .bashrc FILE
#################################################################
