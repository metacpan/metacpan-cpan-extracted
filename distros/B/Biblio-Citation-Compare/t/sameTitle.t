use lib '../lib';
use Biblio::Citation::Compare 'sameTitle';
use Test::More;

my @sameTitleYes = (
  ['A History of Philosophy. Vol. I: Greece and Rome', 'A History of Philosophy. Vol. I : Greece and Rome'],
  ['A book with a bracket (yes? !)', 'A book with a bracket'],
  ['Coyer and the Enlightenment (Studies on Voltaire)', 'Coyer and the Enlightenment'],
  ['The Way Out of Agnosticism: Or, the Philosophy of Free Religion', 'The Way Out of Agnosticism: Or, the Philosophy of Free Religion [Microform]'],
  ['Market Versus Nature: The Social Phiosophy [I.E. Philosophy] of Friedrich Hayek', 'Market Versus Nature: the Social Philosophy of Friedrich Hayek'],
  ['The Philosophy of John Norris of Bemerton: (1657-1712)', 'The philosophy of John Norris of Bemerton: (1657-1712) (Studien und Materialien zur Geschichte der Philosophie : Kleine Reihe ; Bd. 6)'],
  ['Communitarian International Relations: The Epistemic Foundations of International Relations', 'Communitarian International Relations: The Epistemic Foundations of International Relations (New International Relations)'],
  ['"What is an Apparatus?" and Other Essays', '"What Is an Apparatus?" and Other Essays (Meridian: Crossing Aesthetics)'],



);

my @sameTitleNo = (
  ['A History of Philosophy. Vol. I: Greece and Rome', 'A History of Philosophy. Vol. IV: Descartes to Leibniz'],
  ['Book Review of: "Do We Really Understand Quantum Mechanics?" by Franck Laloë', 'Do We Really Understand Quantum Mechanics?'],
  ['Chapter 1 of xyz', 'Chapter 2 of xyz'],
  ['IV- The first pakladjs lkasdjf', 'X- The first pakladjs lkasdjft'],
  ['Theories of consciousness I', 'Theories of consciousness 2'],
  ['Theories of consciousness:part I', 'Theories of consciousness:part 2'],
  ['The Philosophy of John Norris of Bemerton: (1657-1712)', 'The philosophy of John Norris of Bemerton: (1657-2000)'],
  ['Clearly not the same kalsdfjl;sdfajdfsa lfdkasjfadslkajsdf lasdfkjaf', 'Clearny same the not .x,zcmnvcx zm,xcvnxvc ,mxcvzn xcvxm,zcvnvxc zvv'] 
);

ok(sameTitle($_->[0], $_->[1]), "$_->[0] == $_->[1]") for @sameTitleYes;
ok(!sameTitle($_->[0], $_->[1]), "$_->[0] != $_->[1]") for @sameTitleNo;

done_testing();
