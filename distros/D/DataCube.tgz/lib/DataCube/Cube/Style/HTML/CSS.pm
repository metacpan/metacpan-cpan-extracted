


package DataCube::Cube::Style::HTML::CSS;

use strict;
use warnings;

sub new {
    my($class,%opts) = @_;
    my $self = bless { %opts }, ref($class) || $class;
    $self->{default_css} = $self->default_css;
    return $self;
}

sub css {
    my($self,$css) = @_;
    ($self->{css}) = ($css) and return $self if $css;
    return $self->{css} || $self->{default_css};
}

sub default_css {
    my($self,%opts) = @_;
    my $css = '
        <style type="text/css">
            p {
                font-family:    "Verdana", sans-serif;
                font-size:       70%;
                line-height:    12pt;
                margin-bottom:   0px;
                margin-left:    10px;
                margin-top:     10px;
            }
            body {
                background-color:   white;
                font-family:        "Verdana", sans-serif;
                font-size:          100%;
                margin-left:        0px;
                margin-top:         0px;
            } 
            .note {
                background-color:   #ffffff;
                color:              #336699;
                font-family:        "verdana", sans-serif;
                font-size:          100%;
                margin-bottom:       0px;
                margin-left:         0px;
                margin-top:          0px;
                padding-right:      10px;
            }
            .infotable {
                background-color:   #f0f0e0;
                border-bottom:      #ffffff 0px solid;
                border-collapse:    collapse;
                border-left:        #ffffff 0px solid;
                border-right:       #ffffff 0px  solid;
                border-top:         #ffffff 0px solid;
                border-color:       white;
                font-size:          70%;
                margin-left:        10px;
            } 
            .header {
                background-color:   #cecf9c;
                border-bottom:      #ffffff 1px solid;
                border-left:        #ffffff 1px solid;
                border-right:       #ffffff 1px solid;
                border-top:         #ffffff 1px solid;
                color:              #000000;
                font-weight:        bold;
            } 
            .content {
                background-color:   #e7e7ce;
                border-bottom:      #ffffff 1px solid;
                border-left:        #ffffff 1px solid;
                border-right:       #ffffff 1px solid;
            	border-top:         #ffffff 1px solid;
                padding-left:       3px;
            } 
            h1 {
                background-color:   #484448;
                border-bottom:      #336699 6px solid;
                color:              #ffffff;
                font-size:          130%;
                font-weight:        normal;
                margin:             0em 0em 0em -20px;
                padding-bottom:      8px;
                padding-left:       30px;
                padding-top:        16px;
            } 
            h2 {
                color:              #000000;
                font-size:          80%;
                font-weight:        normal;
                margin-bottom:       3px;
                margin-left:        10px;
                margin-top:         20px;
                padding-right:      20px;
            } 
            .foot {
                background-color:   #ffffff;
                border-bottom:      #ffffff 1px solid;
                border-top:         #ffffff 1px solid;
            }
            .footr {
                background-color:   #ffffff;
                border-bottom:      #ffffff 1px solid;
                border-top:         #ffffff 1px solid;
                border-right:       #efefef 1px solid;
            } 
            .beforeline {
                background-color:   red;
                color:              red;
            }
            .afterline {
                background-color:   green;
                color:              green;
            }
            a:link {
                color:              #336699;
                text-decoration:    underline;
            } 
            a:visited {
                color:              #336699;
            } 
            a:active {
                color:              #336699;
            }
            a:hover {
                color:              #003366;
                text-decoration:    underline;
            }
        </style>';

}


1;



__DATA__

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
 <html xmlns="http://www.w3.org/1999/xhtml" > <head> <meta http-equiv="Content-Type" content="text/html; charset=windows-1251"/> 
 <title> Defragmentation Report </title> 
 <style type="text/css">
 P { FONT-FAMILY: "Verdana", sans-serif; FONT-SIZE: 70%; LINE-HEIGHT: 12pt; MARGIN-BOTTOM: 0px; MARGIN-LEFT: 10px; MARGIN-TOP: 10px}
 BODY { BACKGROUND-COLOR: white; FONT-FAMILY: "Verdana", sans-serif; FONT-SIZE: 100%; MARGIN-LEFT: 0px; 	MARGIN-TOP: 0px } 
 .note { BACKGROUND-COLOR:  #ffffff; COLOR: #336699; FONT-FAMILY: "Verdana", sans-serif; FONT-SIZE: 100%; MARGIN-BOTTOM: 0px; MARGIN-LEFT: 0px;MARGIN-TOP: 0px; PADDING-RIGHT: 10px}
 .infotable { BACKGROUND-COLOR: #f0f0e0; BORDER-BOTTOM: #ffffff 0px solid; BORDER-COLLAPSE: collapse; BORDER-LEFT: #ffffff 0px solid; BORDER-RIGHT: #ffffff 0px  solid; BORDER-TOP: #ffffff 0px solid; BORDER-COLOR:white; FONT-SIZE: 70%; MARGIN-LEFT: 10px } 
 .header { BACKGROUND-COLOR: #cecf9c; BORDER-BOTTOM: #ffffff 1px solid; BORDER-LEFT: #ffffff 1px solid; BORDER-RIGHT: #ffffff 1px solid;  BORDER-TOP: #ffffff 1px solid; COLOR: #000000; FONT-WEIGHT: bold } 
 .content { BACKGROUND-COLOR: #e7e7ce; BORDER-BOTTOM: #ffffff 1px solid; BORDER-LEFT: #ffffff 1px solid; BORDER-RIGHT: #ffffff 1px solid; 	BORDER-TOP: #ffffff 1px solid;  PADDING-LEFT: 3px } 
 H1 { BACKGROUND-COLOR: #003366; BORDER-BOTTOM: #336699 6px solid; COLOR: #ffffff; FONT-SIZE: 130%; FONT-WEIGHT: normal; MARGIN: 0em 0em 0em -20px; PADDING-BOTTOM: 8px;  PADDING-LEFT: 30px; PADDING-TOP: 16px } 
 H2 { COLOR: #000000; FONT-SIZE: 80%; FONT-WEIGHT: bold; MARGIN-BOTTOM: 3px; MARGIN-LEFT: 10px; MARGIN-TOP: 20px; PADDING-RIGHT: 20px } 
 .foot { BACKGROUND-COLOR: #ffffff; BORDER-BOTTOM: #ffffff 1px solid; BORDER-TOP: #ffffff 1px solid; } 
 .beforeline { BACKGROUND-COLOR: red;  COLOR: red; }
 .afterline { BACKGROUND-COLOR: green;  COLOR: green; }
 A:link { COLOR: #336699; TEXT-DECORATION: underline } 
 A:visited { COLOR: #336699; } 
 A:active { COLOR: #336699; }
 A:hover { COLOR: #003366; TEXT-DECORATION: underline }
 </style> </head> <body> 
 <h1>Auslogics Disk Defrag</h1> 
<p><span class="note"><strong >Last Time Defragmentation:                                                                                                                                                                                                                                     </strong>4/2/2009 12:14:20 PM                                                                                                                                                                                                                                           <br></span></p>
 <h2>Disk: Local Disk (C:), NTFS                                                                                                                                                                                                                                    </h2> 
 <table cellpadding="2" cellspacing="0" width="98%" border="1" bordercolor="white" class="infotable"> 
 <tr> <td class="header" colspan="2">Defragmentation Summary                                                                                                                                                                                                                                        </td> </tr> 
 <tr> <td class="content"  width="50%">&nbsp;</td> <td class="content">&nbsp;</td> </tr> 
 <tr> <td class="foot" align="right">Auslogics Disk Defrag Version                                                                                                                                                                                                                                  :</td> <td class="foot">1.6.24.355 (diskdefrag.exe)                                                                                                                                                                                                                                    </td> </tr> 
 <tr> <td class="foot" align="right">Disk Size                                                                                                                                                                                                                                                      :</td> <td class="foot">298.09 GB                                                                                                                                                                                                                                                      </td> </tr> 
 <tr> <td class="foot" align="right">Free Size                                                                                                                                                                                                                                                      :</td> <td class="foot">263.14 GB                                                                                                                                                                                                                                                      </td> </tr> 
 <tr> <td class="foot" align="right">Clusters                                                                                                                                                                                                                                                       :</td> <td class="foot">78142456                                                                                                                                                                                                                                                       </td> </tr> 
 <tr> <td class="foot" align="right">Sectors per cluster                                                                                                                                                                                                                                            :</td> <td class="foot">8                                                                                                                                                                                                                                                              </td> </tr> 
 <tr> <td class="foot" align="right">Bytes per sector                                                                                                                                                                                                                                               :</td> <td class="foot">512                                                                                                                                                                                                                                                            </td> </tr> 
 <tr> <td class="foot" align="right">Started defragmentation at                                                                                                                                                                                                                                     :</td> <td class="foot">4/2/2009 12:14:20 PM                                                                                                                                                                                                                                           </td> </tr> 
 <tr> <td class="foot" align="right">Completed defragmentation at                                                                                                                                                                                                                                   :</td> <td class="foot">4/2/2009 12:15:55 PM                                                                                                                                                                                                                                           </td> </tr> 
 <tr> <td class="foot" align="right">Elapsed time                                                                                                                                                                                                                                                   :</td> <td class="foot">00:01:35                                                                                                                                                                                                                                                       </td> </tr> 
 <tr> <td class="foot" align="right">Total Files                                                                                                                                                                                                                                                    :</td> <td class="foot">142005                                                                                                                                                                                                                                                         </td> </tr> 
 <tr> <td class="foot" align="right">Total Directories                                                                                                                                                                                                                                              :</td> <td class="foot">24809                                                                                                                                                                                                                                                          </td> </tr> 
 <tr> <td class="foot" align="right">Fragmented File Count                                                                                                                                                                                                                                          :</td> <td class="foot">88                                                                                                                                                                                                                                                             </td> </tr> 
 <tr> <td class="foot" align="right">Defragmented File Count                                                                                                                                                                                                                                        :</td> <td class="foot">88                                                                                                                                                                                                                                                             </td> </tr> 
 <tr> <td class="foot" align="right">Skipped File Count                                                                                                                                                                                                                                             :</td> <td class="foot">0                                                                                                                                                                                                                                                              </td> </tr> 
 <tr> <td class="foot" align="right"><strong><strong>Fragmentation Before</strong>                                                                                                                                                                                                                          :</strong></td> <td class="foot">0.04%                                                                                                                                                                                                                                                          &nbsp;&nbsp;<span class="beforeline" align="right">                                                                                                                                                                                                                                                               :</span></td> </tr> 
 <tr> <td class="foot" align="right"><strong><strong>Fragmentation After</strong>                                                                                                                                                                                                                           :</strong></td> <td class="foot">0.00%                                                                                                                                                                                                                                                          &nbsp;&nbsp;<span class="afterline">                                                                                                                                                                                                                                                               :</span></td> </tr> 
 </table> <br />  <table cellpadding="2" cellspacing="0" width="98%" border="1" bordercolor="white" class="infotable"> 
 <tr> <td class="header" colspan="5">Defragmentation Details</td> </tr> 
 <tr> <td class="content" width="5%">Fragments</td> <td class="content" align="center" width="12%">Clusters</td>  <td class="content" width="10%">Size</td> <td class="content" align="center" width="8%">Result</td> <td class="content">File Name</td> </tr>  <tr> <td class="foot" align="center">17</td> <td class="foot" align="center">128526 / 128590</td>  <td class="foot">256.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\Config.Msi\</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">9943 / 9956</td>  <td class="foot">48.68 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\RAC\StateData\WDCEvents.ECF442AB01C04AB4880DD1E1F5F44D8D</td> </tr> 
 <tr> <td class="foot" align="center">9</td> <td class="foot" align="center">9956 / 9987</td>  <td class="foot">550.72 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\Windows\WER\ReportQueue\Report0bda07cc\WER5F9.tmp.mdmp</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">738492 / 741237</td>  <td class="foot">10.72 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\Windows Defender\Definition Updates\Backup\mpasbase.vdm</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">23720 / 23758</td>  <td class="foot">149.90 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\Windows Defender\Definition Updates\Backup\mpasdlta.vdm</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">746826 / 748309</td>  <td class="foot">5.79 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\Windows Defender\Definition Updates\Backup\mpengine.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">9987 / 9989</td>  <td class="foot">5.70 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\Windows Defender\Scans\History\Results\Resource\{A3D9C53F-22F8-44B0-9EA8-4CCA10FD0CD3}</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">31340 / 31386</td>  <td class="foot">181.03 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\Microsoft\Windows Defender\Support\MPLog-11022006-074300.log</td> </tr> 
 <tr> <td class="foot" align="center">4</td> <td class="foot" align="center">9989 / 10000</td>  <td class="foot">41.56 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\nvModes.001</td> </tr> 
 <tr> <td class="foot" align="center">4</td> <td class="foot" align="center">22527 / 22538</td>  <td class="foot">41.56 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\ProgramData\nvModes.dat</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">162951 / 163143</td>  <td class="foot">768.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\Users\david\AppData\Local\Microsoft\Windows\UsrClass.dat</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">10000 / 10003</td>  <td class="foot">9.99 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\Users\david\AppData\Local\Microsoft\Windows\WindowsUpdate.log</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">10003 / 10006</td>  <td class="foot">9.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\Users\david\AppData\Local\Temp\MpSigStub.log</td> </tr> 
 <tr> <td class="foot" align="center">4</td> <td class="foot" align="center">22538 / 22543</td>  <td class="foot">17.58 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\Users\david\AppData\Local\Temp\SetupExe(20090402121055EE8).log</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">22543 / 22551</td>  <td class="foot">17.29 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\Users\david\AppData\Roaming\Auslogics\Disk Defrag\Reports\C_Disk_Defrag_Report.html</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">119738 / 119793</td>  <td class="foot">217.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\Microsoft.Build.Con#\c12ffa08ede3b1c95a09eccadefd06be\Microsoft.Build.Conversion.v3.5.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">557048 / 557483</td>  <td class="foot">1.70 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\Microsoft.Build.Eng#\f3f6d3c43aeaf1935dfa3ecfbba0653f\Microsoft.Build.Engine.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">89174 / 89193</td>  <td class="foot">73.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\Microsoft.Build.Fra#\b36d40a066269e661d2e3ff3ed7e1f3c\Microsoft.Build.Framework.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">557483 / 557941</td>  <td class="foot">1.79 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\Microsoft.Build.Tas#\44c71eb8c39a199d8da87a63e78a722d\Microsoft.Build.Tasks.v3.5.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">95475 / 95515</td>  <td class="foot">157.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\Microsoft.Build.Uti#\ca125c4f85510b992fadf2b12132e9d8\Microsoft.Build.Utilities.v3.5.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">93428 / 93461</td>  <td class="foot">130.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\MSBuild\661d2603712f6a2748c60becb56db84d\MSBuild.ni.exe</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">189413 / 189568</td>  <td class="foot">619.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.AddIn\5900b886988a84154f3fbcb278907dd7\System.AddIn.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">119036 / 119057</td>  <td class="foot">81.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.AddIn.Contra#\d8b404d96cc6acefe2da61b4b3e9b1b1\System.AddIn.Contract.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">119793 / 119827</td>  <td class="foot">132.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Data.DataSet#\af40de208418621f53744915996bac56\System.Data.DataSetExtensions.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">753863 / 756286</td>  <td class="foot">9.46 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Data.Entity\760c02bc209ec17322b66af1696eb907\System.Data.Entity.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">191079 / 191264</td>  <td class="foot">739.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Data.Entity.#\ebf1a793408ea50bde06ad35af27ca2a\System.Data.Entity.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">191770 / 192000</td>  <td class="foot">917.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Data.Service#\3ec39ed697e98944e41fff368718fbbb\System.Data.Services.Client.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">149912 / 149999</td>  <td class="foot">346.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Data.Service#\7ad3ebf22ef766e1fabb3a3070607f79\System.Data.Services.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">741237 / 741562</td>  <td class="foot">1.27 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Data.Services\0faa5e4ca9bfeb801afd8167b29c5823\System.Data.Services.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">485491 / 485707</td>  <td class="foot">860.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.DirectorySer#\ed32cf3c3ed5d01096db115537c99341\System.DirectoryServices.AccountManagement.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">198174 / 198255</td>  <td class="foot">323.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Management.I#\348fc7121c213b7d64db4a060b3bf865\System.Management.Instrumentation.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">511976 / 512128</td>  <td class="foot">606.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Net\e40fffc0e6292693b77479f3473f87ec\System.Net.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">742318 / 742722</td>  <td class="foot">1.58 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.ServiceModel#\d07c5a8a35675b1fc02a641d9632f80e\System.ServiceModel.Web.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">119827 / 119862</td>  <td class="foot">138.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Web.Abstract#\fd6950345a1168730b83c0dd5ce02e0d\System.Web.Abstractions.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">460365 / 460499</td>  <td class="foot">534.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Web.DynamicD#\932e01f410d91cf6502a5a359ac58650\System.Web.DynamicData.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">428345 / 428426</td>  <td class="foot">321.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Web.Entity\fad96b6abad482337c003971a2714a5b\System.Web.Entity.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">428510 / 428584</td>  <td class="foot">294.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Web.Entity.D#\66852e1be6a9d70d746d083ddf6bf1b8\System.Web.Entity.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">741562 / 741772</td>  <td class="foot">839.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Web.Extensio#\ed8b05d06572d14417b0b883fb3087eb\System.Web.Extensions.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">125592 / 125624</td>  <td class="foot">126.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Web.Routing\8f1e1d3975e3cd442e208d5699d7f1c6\System.Web.Routing.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">23758 / 23768</td>  <td class="foot">37.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Windows.Pres#\c8227e36bde3ffdbece7413d9ca9867d\System.Windows.Presentation.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">743144 / 743466</td>  <td class="foot">1.26 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.WorkflowServ#\4219cdb80d0eecd2ff28ec71656066ca\System.WorkflowServices.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">458150 / 458248</td>  <td class="foot">391.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\System.Xml.Linq\d55cfe7d7a8d54165400735d3707f653\System.Xml.Linq.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">77137 / 77147</td>  <td class="foot">40.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_32\</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">155865 / 155900</td>  <td class="foot">139.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\Microsoft.Build.Fra#\3826af21572c4ed047ca67df4907fbe7\Microsoft.Build.Framework.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">748309 / 748527</td>  <td class="foot">869.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.AddIn\a91595ee00ce878c79e592df6d6cd41b\System.AddIn.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">156160 / 156199</td>  <td class="foot">153.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.AddIn.Contra#\23303d59c82a7753ca9b24661f4af710\System.AddIn.Contract.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">163961 / 163994</td>  <td class="foot">129.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.ComponentMod#\1ba0bc232b27723c99a478061682e32e\System.ComponentModel.DataAnnotations.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">189568 / 189616</td>  <td class="foot">190.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Data.DataSet#\01fe77501862a5f2b6af80b39a0e4f8e\System.Data.DataSetExtensions.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">748527 / 748791</td>  <td class="foot">1.03 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Data.Entity.#\249e6c7146c56b0eed47c8096e0390be\System.Data.Entity.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">199896 / 200016</td>  <td class="foot">478.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Data.Service#\4194a10e4f38defe074a141e1be688d7\System.Data.Services.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">748791 / 749103</td>  <td class="foot">1.22 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Data.Service#\ae4d44df4738763eaaaed4e131097e1b\System.Data.Services.Client.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">749103 / 749554</td>  <td class="foot">1.76 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Data.Services\0e0f2f03c880827eaf15871ba8653605\System.Data.Services.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">749554 / 749852</td>  <td class="foot">1.16 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.DirectorySer#\f024b0c9acdd14b6599c02816ccbbf92\System.DirectoryServices.AccountManagement.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">513945 / 514076</td>  <td class="foot">521.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Management.I#\7a53d6ff261d393e21297dfae234fe7d\System.Management.Instrumentation.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">284475 / 284698</td>  <td class="foot">890.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Net\422be391b9f8f7644724bd8c31198b0f\System.Net.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">756286 / 756833</td>  <td class="foot">2.14 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.ServiceModel#\f05f8904eb91f7d1f7e58f14f0d2fedd\System.ServiceModel.Web.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">124574 / 124588</td>  <td class="foot">53.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Web.DynamicD#\8831e8efbd19fb16e6cd03beea584f9a\System.Web.DynamicData.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">578936 / 579121</td>  <td class="foot">736.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Web.DynamicD#\edeb07b4c9505af1ac4fa229ab440e0b\System.Web.DynamicData.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">284316 / 284426</td>  <td class="foot">439.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Web.Entity\b051a74d3ab4ee32a72625e2daaca164\System.Web.Entity.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">430198 / 430296</td>  <td class="foot">389.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Web.Entity.D#\44363cb941fe8ccb67314946be323b3e\System.Web.Entity.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">756833 / 757115</td>  <td class="foot">1.10 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Web.Extensio#\84abb4defdf6c46004bb2f2185dfeedf\System.Web.Extensions.Design.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">192000 / 192046</td>  <td class="foot">183.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Web.Routing\e07ca0157a3ac8142dc8b1378bcf7b9a\System.Web.Routing.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">757115 / 757544</td>  <td class="foot">1.67 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.WorkflowServ#\2cab743c8b3a7e30bb01023bdb02f0a0\System.WorkflowServices.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">3</td> <td class="foot" align="center">575981 / 576111</td>  <td class="foot">517.50 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\System.Xml.Linq\7a7193e7727103aeaf3d763cdecfb42f\System.Xml.Linq.ni.dll</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">91971 / 91983</td>  <td class="foot">48.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\assembly\NativeImages_v2.0.50727_64\</td> </tr> 
 <tr> <td class="foot" align="center">6</td> <td class="foot" align="center">190838 / 190870</td>  <td class="foot">125.34 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\Installer\MSI4F5C.tmp</td> </tr> 
 <tr> <td class="foot" align="center">8</td> <td class="foot" align="center">2639292 / 2648764</td>  <td class="foot">36.98 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\Logs\CBS\CBS.log</td> </tr> 
 <tr> <td class="foot" align="center">33</td> <td class="foot" align="center">758020 / 758368</td>  <td class="foot">1.36 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727\ngen_service.log</td> </tr> 
 <tr> <td class="foot" align="center">34</td> <td class="foot" align="center">764154 / 764568</td>  <td class="foot">1.62 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\Microsoft.NET\Framework64\v2.0.50727\ngen_service.log</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">129786 / 129803</td>  <td class="foot">65.51 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\PFRO.log</td> </tr> 
 <tr> <td class="foot" align="center">34</td> <td class="foot" align="center">764568 / 765058</td>  <td class="foot">1.91 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\Prefetch\Layout.ini</td> </tr> 
 <tr> <td class="foot" align="center">82</td> <td class="foot" align="center">765058 / 765558</td>  <td class="foot">5.12 MB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\Prefetch\ReadyBoot\Trace3.fx</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">158149 / 158173</td>  <td class="foot">95.47 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\ResCache.dir</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">188165 / 188411</td>  <td class="foot">980.98 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment0.cmf</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">31046 / 31058</td>  <td class="foot">46.94 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment0.toc</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">187000 / 187182</td>  <td class="foot">727.70 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment1.cmf</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">95044 / 95056</td>  <td class="foot">46.94 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment1.toc</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">190455 / 190647</td>  <td class="foot">767.39 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment2.cmf</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">95515 / 95527</td>  <td class="foot">46.94 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment2.toc</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">634168 / 634392</td>  <td class="foot">894.79 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment3.cmf</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">117893 / 117905</td>  <td class="foot">46.94 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment3.toc</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">186124 / 186294</td>  <td class="foot">676.72 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment4.cmf</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">124588 / 124600</td>  <td class="foot">46.94 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\rc0008\Segment4.toc</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">187708 / 187861</td>  <td class="foot">608.40 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\rescache\ResCache.mni</td> </tr> 
 <tr> <td class="foot" align="center">5</td> <td class="foot" align="center">624783 / 624906</td>  <td class="foot">490.88 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\SoftwareDistribution\SelfUpdate\WUClient-SelfUpdate-Aux-TopLevel~31bf3856ad364e35~amd64~~7.2.6001.788.mum</td> </tr> 
 <tr> <td class="foot" align="center">5</td> <td class="foot" align="center">749852 / 750041</td>  <td class="foot">754.62 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\SoftwareDistribution\SelfUpdate\WUClient-SelfUpdate-Core-TopLevel~31bf3856ad364e35~amd64~~7.2.6001.788.mum</td> </tr> 
 <tr> <td class="foot" align="center">4</td> <td class="foot" align="center">634392 / 634512</td>  <td class="foot">224.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\System32\LogFiles\Scm\SCM.EVM</td> </tr> 
 <tr> <td class="foot" align="center">2</td> <td class="foot" align="center">765558 / 765686</td>  <td class="foot">512.00 KB</td> <td class="foot" align="center">OK</td> <td class="foot"> C:\WINDOWS\System32\LogFiles\Scm\SCM.EVM.3</td> </tr> 

</table>
<br /><h2><font size ="-2">Auslogics Pty Ltd - <a href="http://www.auslogics.com/go/diskdefrag/en/software/disk-defrag">Visit site</a></font></h2></body></html>



1;






