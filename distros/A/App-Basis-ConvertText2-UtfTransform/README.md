# App-Basis-ConvertText2-UtfTransform

A number of popular websites (eg twitter) do not allow the use of HTML to create
bold/italic font effects or perform smily transformations

However we can simulate this with some clever transformations of plain ascii text
into UTF8 codes which are a different font and so effectively create the same effect.

We have transformations for flip (reverses the string and flips upside down,
bold, italic, bubbles,script and leet.

We can only transform A-Z a-z 0-9 and ? ! ,

I have only implemented a small set of smilies, ones that I am likely to use.

## Formatting

* flip     <f>text</f>      upside down and reversed
* bold     <b>text</b>
* italic   <i>text</i>
* bubbles  <o>text</o>
* script   <s>text</s>
* leet     <l>text</l>      LeetSpeak

## Smilies

| smilie                                    | symbol      |
|----------------------------+--------------+-------------|
| <3. :heart:                               | heart       |
| :)                                        | smile       |
| :D                                        | grin        |
| 8-)                                       | cool        |
| :P                                        | pull tongue |
| :(                                        | cry         |
| :(                                        | sad         |
| ;)                                        | wink        |
| :halo:                                    | halo        |
| :devil:, :horns:                          | devil horns |
| (c)                                       | copyright   |
| (r)                                       | registered  |
| (tm)                                      | trademark   |
| :email:                                   | email       |
| :yes:                                     | tick        |
| :no:                                      | cross       |
| :beer:                                    | beer        |
| :wine:, :wine_glass:                      | wine        |
| :cake:                                    | cake        |
| :star:                                    | star        |
| :ok:, :thumbsup:                          | thumbsup    |
| :bad:, :thumbsdown:                       | thumbsup    |
| :ghost:                                   | ghost       |
| :skull:                                   | skull       |
| :hourglass:                               | hourglass   |
| :time:                                    | watch face  |
| :sleep:                                   | sleep       |

