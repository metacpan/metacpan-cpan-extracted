package DBIx::Perform::Messages;




our %languages = (
  "en_US" => 0,
  "en_GB" => 0,
  "fr" => 1,
  "es" => 2,
  "pt" => 3,
);




our @messages = ([



"DBIx::Perform.\r
\r
The PERFORM Menu presents you with the following options:\r
\r
 > Query            Searches the table\r
 > Next             Displays the next row in the Current List\r
 > Previous         Displays the previous row in the Current List\r
 > View             Runs editor commands to display BLOB contents.\r
                    BLOB data types are available only on OnLine systems.\r
 > Add              Adds data to the active table\r
 > Update           Changes a row in the active table\r
 > Remove           Deletes a row from the active table\r
 > Table            Selects the currently active table\r
 > Screen           Displays the next page of the form\r
 > Current          Displays the current row of the active table\r
 > Master           Selects the master table of the currently active table\r
 > Detail           Selects a detail table of the currently active table\r
 > Output           Sends a form or report to an output destination\r
 > Exit             Returns to the Perform Menu\r

\r
PROCEDURE:\r
\r
Enter the first letter of the menu option you want:  q for Query, n for Next,\r
p for Previous, v for View, a for Add, u for Update, r for Remove, t for Table,\r
s for Screen, c for Current, m for Master, d for Detail, o for Output, or\r
e for Exit.\r
\r
Use the Next and Previous options to view the next or previous row in the\r
Current List.  First use the Query option to generate a Current List (a list of\r
all the rows that satisfy your query).  If there is more than one row in the\r
Current List, you can select the Next option to look at the next row.  After\r
you use Next, you can use the Previous option to look at the previous row.\r
\r
On OnLine systems, use the View option to display the contents of TEXT and\r
BYTE fields using the external programs specified in the PROGRAM attributes\r
or a default system editor for TEXT fields. BYTE fields cannot be displayed\r
unless the PROGRAM attribute is present.\r
\r
Use the Screen option to view other pages of your form.  If you have only one\r
page, the Screen option will not do anything.  If you have more than one page,\r
the Screen option will display the next page.  The \"Page x of y\" line on the\r
fourth line of the screen tells you how many pages you have and which one you\r
are looking at now.  When you reach the last page of the form, select the\r
Screen option to cycle back to the first page.\r

Use the Exit option to leave the PERFORM Menu and return to the Perform Menu.\r
After you select the Exit option, Perform displays the Perform Menu.\r
\r
\r
QUIT:\r
\r
Select the Exit option to leave the PERFORM Menu and return to the FORM Menu.\r
\r
\r
\r
NOTES:\r
\r
You cannot select Update, Next, Previous, or Remove until you have generated a\r
Current List with Query.\r
",

"FIELD EDITING CONTROL KEYS:\r
CTRL X    :  Deletes a character\r
CTRL A    :  Toggles in and out of character insertion mode\r
CTRL D    :  Clears to the end of the field\r
left      :  Backspace\r
right     :  Forward space\r
up        :  Traverse backwards through the fields\r
CTRL F    :  'Fast-forward' through the fields\r
CTRL B    :  'Fast-reverse' through the fields\r
CTRL W    :  Display help message\r
CR        :  Next field\r
CTRL I    :  Next field\r
down      :  Next field\r
!         :  Invokes the BLOB editor if in a BLOB field.\r
ESC       :  Entry Complete\r
CTRL C    :  Abort Command\r
\r
\r
QUERY COMPARISON SYMBOLS:\r
<     Less than                 <=    Less than or equal\r
>     Greater than              >=    Greater than or equal\r
=     Equal                     <>    Not equal\r
>>    Last value (only for indexed columns, without other comparisons)\r
<<    First value (same conditions as last value)\r
:     Range  (inclusive)\r
|     OR condition\r
The colon for range comparison is typed between the desired range values\r
The pipe symbol for OR separates the different possibilities\r
      All other symbols are typed in front of the column value\r
An asterisk (*) is used for wild card comparison of character columns\r
A blank field means don't care\r
      To match for a blank character field, use the equality symbol\r
\r
\r
",

"Perform",
"Query",
"Next",
"Previous",
"View",
"Add",
"Update",
"Remove",
"Table",
"Screen",
"Current",
"Master",
"Detail",
"Output",
"Exit",

"Yes",
"No",

"ESCAPE queries.  INTERRUPT discards query.  ARROW keys move cursor.",
"ESCAPE adds new data.  INTERRUPT discards it.  ARROW keys move cursor.",
"ESCAPE changes data.  INTERRUPT discards changes.",
"Enter output file (default is perform.out): ",

"Searches the active database table.",
"Shows the next row in the Current List.",
"Shows the previous row in the Current List.",
"Runs editor commands to display BLOB contents.",
"Adds new data to the active database table.",
"Changes this row in the active database table.",
"Deletes a row from the active database table.",
"Selects the current table.",
"Shows the next page of the form.",
"Displays the current row of the current table.",
"Selects the master table of the current table.",
"Selects a detail table of the current table.",
"Outputs selected rows in form or report format.",
"Returns to the INFORMIX-SQL Menu.",

"Removes this row from the active table.",
"Does NOT remove this row from the active table.",

" There are no more rows in the direction you are going  ",
"This feature is not supported",
" There are no rows in the current list  ",
" No master table has been specified for this table  ",
" No detail table has been specified for this table  ",
"DB Error on prepare",
" Error in field  ",
"No query is active.",
"Database error",
"Searching..",
"Searching...",
"Searching....",
"no rows found",
"1 row found",
"%d rows found",
"%d rows found",
"Row added",
"Row deleted",
"No fields changed",
"row affected",
"add: SQL prepare failure",
"Failed to update display from the database",
"This value is not among the valid possibilities",
" The current row position contains a deleted row",
"Row data was not current.  Refreshed with current data.",
"Someone else has updated this row.",
"Someone else has deleted this row.",

" This is an invalid value -- it does not exist in %s table",
" Invalid value -- its composite value does not exist in %s table ",
" The column %s does not allow null values.  ",



], [



"DBIx::Perform.\r
\r
La PERFORM menu vous présente les options suivantes:\r
\r
  > Query            Recherches de la table\r
  > Suivant          Affiche la ligne suivante dans la Liste actuelle\r
  > Précédent        Affiche la ligne précédente dans la Liste actuelle\r
  > Vue              Fonctionne éditeur de commandes pour afficher le contenu BLOB.\r
                     BLOB types de données ne sont disponibles que sur les systèmes en ligne.\r
  > Ajouter          Ajoute des données sur le tableau actif\r
  > Mise à jour      d'affilée Changements dans le tableau actif\r
  > Effacer        Efface une ligne dans le tableau actif\r
  > Table            Sélectionne la table actuellement actif\r
  > Look             Affiche la page suivante de la forme\r
  > Capitaine        Affiche la ligne du tableau actif\r
  > Master           Sélectionne la table principale de la table actuellement actif\r
  > Détail           Sélectionne un tableau détaillé de la table actuellement actif\r
  > Output           Envoie un rapport de la forme ou à une destination de sortie\r
  > Fin              retours à la Effectuez Menu\r

\r
PROCEDURE:\r
\r
Entrez la première lettre de l'option de menu que vous voulez: pour Query q, n pour suivante,\r
P pour la précédente, pour Voir, à Ajouter, et les mises à jour, pour Retirez r, t pour le tableau,\r
S pour l'écran, c pour courant, m pour le Maître, pour d Détail, portant pour la sortie, ou\r
E pour la sortie.\r
\r
Utilisez l'option Suivant et Précédent pour afficher la ligne suivante ou précédente dans le\r
Liste courante. Première utilisation de l'option de requête pour générer un courant List (une liste des\r
Toutes les lignes qui satisfont votre requête). S'il ya plus d'une ligne dans le\r
Liste actuelle, vous pouvez sélectionner l'option suivante à examiner la prochaine ligne. Après\r
Suivant que vous utilisez, vous pouvez utiliser l'option précédente de regarder la ligne précédente.\r
\r
Sur OnLine, utilisez l'option Afficher pour afficher le contenu du TEXT et\r
BYTE champs à l'aide de l'programmes mentionnés dans l'PROGRAMME attributs\r
Ou d'un éditeur de système par défaut pour les champs de type TEXT. BYTE champs ne peuvent pas être affichés\r
À moins que l'attribut PROGRAMME est présent.\r
\r
Utilisez l'option de l'écran pour voir les autres pages de votre formulaire. Si vous avez seulement un\r
Page, l'écran option ne fera rien. Si vous avez plus d'une page,\r
L'option de l'écran affichera la page suivante. Le \"page x de y\" sur la ligne\r
Quatrième ligne de l'écran vous indique le nombre de pages que vous avez et que l'on vous\r
Examinons maintenant. Lorsque vous arrivez à la dernière page du formulaire, sélectionnez le\r
Screen cycle option pour revenir à la première page.\r

Utilisez l'option Quitter pour quitter le menu PERFORM et revenir au menu Exécuter.\r
Après avoir sélectionné l'option Quitter, Exécuter affiche le menu Exécuter.\r
\r
\r
QUIT:\r
\r
Sélectionnez l'option Quitter pour quitter le menu PERFORM et revenir au menu FORM.\r
\r
\r
\r
NOTES:\r
\r
Vous ne pouvez pas sélectionner Actualiser, Suivant, Précédent, Supprimer ou jusqu'à ce que vous ayez généré un\r
Liste actuelle avec Query.\r
",

"DOMAINE DE MONTAGE DE CONTRÔLE CLES:\r
CTRL X    :  Efface un caractère\r
CTRL A    :  Bascule et de sortie du mode insertion de caractères\r
CTRL D    :  Efface à la fin du champ\r
Gauche    :  Backspace\r
Droite    :  Forward espace\r
Up        :  Traverse reculer dans le champs\r
CTRL F    :  'Avance rapide' à travers les champs\r
CTRL B    :  'Fast-inverse' à travers les champs\r
CTRL W    :  Affichage message d'aide\r
CR        :  Prochain champ\r
CTRL I    :  Champ suivant\r
Down      :  Prochain champ\r
!         :  Invoque l'éditeur BLOB si dans un champ BLOB.\r
ESC       :  Entrée Complete\r
CTRL C    :  Interrompre Command\r
\r
\r
COMPARAISON DES SYMBOLES QUERY:\r
<     Moins de                  <= Inférieur ou égal\r
>     Supérieur                 >= Supérieur ou égal\r
=     Egalité                   <> Pas égaux\r
>>    Dernière valeur (uniquement pour les colonnes indexées, sans autres comparaisons)\r
<<    Première valeur (mêmes conditions que la dernière valeur)\r
:     Range (inclusivement)\r
|     OU CONDITION\r
Le colon de gamme est dactylographié comparaison entre la plage des valeurs\r
Le tuyau symbole pour OU sépare les différentes possibilités\r
       Tous les autres symboles sont dactylographiés en face de la colonne valeur\r
Un astérisque (*) est utilisé pour la comparaison des wild card caractère colonnes\r
Un champ vide ne signifie pas\r
       Pour correspondre à un domaine vierge caractère, utiliser le symbole de l'égalité\r
\r
\r
",


"Perform",
"Query",
"Suivant",
"Précédent",
"Vue",
"Ajouter",
"Mise à jour",
"Effacer",
"Table",
"Look",
"Refresh",
"Capitaine",
"Détail",
"Output",
"Fin",

"Oui",
"Non",

"ESC requêtes. INTERROMPRE rejets requête. FLÈCHES déplacer le curseur.",
"ESC ajoute de nouvelles données. INTERROMPRE rejets. FLÈCHES déplacer le curseur.",
"ESC modifications de données. INTERROMPRE déchets de changements.",
"Entrez le fichier de sortie (par défaut perform.out):",

"Recherches de la table de base de données active.",
"Affiche la ligne suivante dans la liste actuelle.",
"Affiche la ligne précédente dans la liste actuelle.",
"Pistes éditeur BLOB commandes pour afficher le contenu.",
"Ajout de nouvelles données à la base de données active table.",
"Les changements de cette ligne dans la table de base de données active.",
"Efface une ligne dans la table de base de données active.",
"Sélectionne la table actuelle.",
"Affiche la page suivante du formulaire.",
"Affiche la ligne de la table actuelle.",
"Sélectionne la table principale de l'actuel tableau.",
"Sélectionne un tableau détaillé de la table.",
"Sorties lignes sélectionnées par la forme ou le format du rapport.",
"Retourne à la INFORMIX-SQL Menu.",

"Enlève cette ligne du tableau actif.",
"Est-ce que cette ligne PAS retirer de la table active.",

"Il n'ya plus de lignes dans la direction où vous allez",
"Cette fonction n'est pas prise en charge",
"Il n'ya pas de lignes dans la liste actuelle",
"Pas de maître de table a été spécifié pour ce tableau",
"Aucun détail de table a été spécifié pour ce tableau",
"Erreur sur la préparer",
"Erreur dans le champ",
"Pas de requête est actif.",
"Erreur de base de données",
"La recherche ..",
"La recherche ...",
"La recherche ....",
"No rangées trouvé",
"1 rangée trouvé",
"%d Rangées trouvé",
"%d Rangées trouvé",
"Rangées ajoutée",
"Rangées supprimée",
"Aucun champs changé",
"Rangées touchés",
"Ajouter: SQL préparer échec",
"Impossible de mettre à jour l'affichage de la base de données",
"Cette valeur n'est pas valable chez les possibilités",
"L'actuelle position contient une rangée de supprimer la ligne",
"Rangée données n'étaient pas à jour. Rafraîchie avec les données actuelles.",
"Quelqu'un d'autre a mis à jour cette ligne.",
"Quelqu'un d'autre a supprimé cette ligne.",

" Ceci est une valeur incorrecte - il n'existe pas dans la table %s",
" Valeur incorrecte - sa valeur composite n'existe pas dans la table %s",
" La colonne %s n'accepte pas les valeurs nulles.  ",


],[



"espa�ol 1",
"espa�ol 2",



],[



"portugu�s 1",
"portugu�s 2",



]);
