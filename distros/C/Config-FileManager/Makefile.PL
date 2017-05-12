###############################################################################
#                                                                             #
#    Copyright © 2012-2013 -- LIRMM/UM2                                       #
#                            (Laboratoire d'Informatique, de Robotique et de  #
#                             Microélectronique de Montpellier /              #
#                             Université de Montpellier 2)                    #
#                             IRB/INSERM                                      #
#                            (Institut de Recherche en Biothérapie /          #
#                             Institut National de la Santé et de la          #
#                             Recherche Médicale)                             #
#                                                                             #
#  Auteurs/Authors: Alban MANCHERON  <alban.mancheron@lirmm.fr>               #
#                   Nicolas PHILIPPE <nicolas.philippe@inserm.fr>             #
#                                                                             #
#  -------------------------------------------------------------------------  #
#                                                                             #
#  Ce fichier  fait partie  du Pipeline  de traitement  de données NGS de la  #
#  plateforme ATGC labélisée par le GiS IBiSA.                                #
#                                                                             #
#  Ce logiciel est régi  par la licence CeCILL  soumise au droit français et  #
#  respectant les principes  de diffusion des logiciels libres.  Vous pouvez  #
#  utiliser, modifier et/ou redistribuer ce programme sous les conditions de  #
#  la licence CeCILL  telle que diffusée par le CEA,  le CNRS et l'INRIA sur  #
#  le site "http://www.cecill.info".                                          #
#                                                                             #
#  En contrepartie de l'accessibilité au code source et des droits de copie,  #
#  de modification et de redistribution accordés par cette licence, il n'est  #
#  offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,  #
#  seule une responsabilité  restreinte pèse  sur l'auteur du programme,  le  #
#  titulaire des droits patrimoniaux et les concédants successifs.            #
#                                                                             #
#  À  cet égard  l'attention de  l'utilisateur est  attirée sur  les risques  #
#  associés  au chargement,  à  l'utilisation,  à  la modification  et/ou au  #
#  développement  et à la reproduction du  logiciel par  l'utilisateur étant  #
#  donné  sa spécificité  de logiciel libre,  qui peut le rendre  complexe à  #
#  manipuler et qui le réserve donc à des développeurs et des professionnels  #
#  avertis  possédant  des  connaissances  informatiques  approfondies.  Les  #
#  utilisateurs  sont donc  invités  à  charger  et  tester  l'adéquation du  #
#  logiciel  à leurs besoins  dans des conditions  permettant  d'assurer  la  #
#  sécurité de leurs systêmes et ou de leurs données et,  plus généralement,  #
#  à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.         #
#                                                                             #
#  Le fait  que vous puissiez accéder  à cet en-tête signifie  que vous avez  #
#  pris connaissance  de la licence CeCILL,  et que vous en avez accepté les  #
#  termes.                                                                    #
#                                                                             #
#  -------------------------------------------------------------------------  #
#                                                                             #
#  This File is part of the NGS data processing Pipeline of the ATGC          #
#  accredited by the IBiSA GiS.                                               #
#                                                                             #
#  This software is governed by the CeCILL license under French law and       #
#  abiding by the rules of distribution of free software. You can use,        #
#  modify and/ or redistribute the software under the terms of the CeCILL     #
#  license as circulated by CEA, CNRS and INRIA at the following URL          #
#  "http://www.cecill.info".                                                  #
#                                                                             #
#  As a counterpart to the access to the source code and rights to copy,      #
#  modify and redistribute granted by the license, users are provided only    #
#  with a limited warranty and the software's author, the holder of the       #
#  economic rights, and the successive licensors have only limited            #
#  liability.                                                                 #
#                                                                             #
#  In this respect, the user's attention is drawn to the risks associated     #
#  with loading, using, modifying and/or developing or reproducing the        #
#  software by the user in light of its specific status of free software,     #
#  that may mean that it is complicated to manipulate, and that also          #
#  therefore means that it is reserved for developers and experienced         #
#  professionals having in-depth computer knowledge. Users are therefore      #
#  encouraged to load and test the software's suitability as regards their    #
#  requirements in conditions enabling the security of their systems and/or   #
#  data to be ensured and, more generally, to use and operate it in the same  #
#  conditions as regards security.                                            #
#                                                                             #
#  The fact that you are presently reading this means that you have had       #
#  knowledge of the CeCILL license and that you accept its terms.             #
#                                                                             #
###############################################################################
#
# $Id: Makefile.PL,v 1.4 2014/04/09 07:33:38 doccy Exp $
#
###############################################################################
#
# $Log: Makefile.PL,v $
# Revision 1.4  2014/04/09 07:33:38  doccy
# Removing PREREQ_FATAL in makefile (thanks to both Jérôme Audoux and Slaven
# Rezic).
#
# Revision 1.3  2013/05/22 11:38:44  doccy
# Update Copyright informations
#
# Revision 1.2  2013/05/22 10:35:12  doccy
# Add CéCILL Copyright Notice
#
# Revision 1.1.1.1  2013/05/21 16:43:23  doccy
# Perl Module for manage configuration files.
#
###############################################################################

use 5.001000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME              => 'Config::FileManager',
	      VERSION_FROM      => "lib/Config/FileManager.pm",
	      ABSTRACT_FROM     => 'lib/Config/FileManager.pm', # retrieve abstract from module
              PREREQ_FATAL      => 0,
	      PREREQ_PM         => {
				    "Exporter" => 5.62,
				    "File::Basename" => 2.76,
				    "File::HomeDir" => 0.97,
				    "POSIX" => 1.13,
				    "Pod::Usage" => 1.35,
				    "strict" => 1.04,
				    "utf8" => 1.07,
				    "warnings" => 1.06,
				    "Text::Patch" => 1.8,
				    "Text::Diff" => 1.41,
				    "Data::Dumper" => 2.125,
				    "Carp" => 1.17,
				   },
	      AUTHOR            => 'Alban MANCHERON <alban.mancheron@lirmm.fr>, Nicolas PHILIPPE <nicolas.philippe@inserm.fr>',
              ($ExtUtils::MakeMaker::VERSION >= 6.3002
               ? ('LICENSE'=> 'open_source')
               : ()),
              clean             => { FILES => 'Config-FileManager-*' },
	     );
