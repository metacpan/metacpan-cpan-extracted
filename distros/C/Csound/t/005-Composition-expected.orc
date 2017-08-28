sr     = 44100
kr     =  4410
ksmps  =    10
nchnls =     2
;0dbfs =     1

instr 1

  i_freq init cpspch(p4)

  asig oscili 5000, i_freq, 1
  outs asig, asig

endin

instr 2



  asig oscili 2000, 440, 2
  outs asig, asig
    

endin
