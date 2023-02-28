	subroutine read_dataxy(x,y,n,fin,iin,iwrit)
!
! Reads file containing (x,y) pairs and an arbitrary number of
! comment lines
! before these pairs. The (x,y) pairs are returned in arrays x and y.
! The
! comment lines are written on the terminal.
!
! n     = number of (x,y) pairs in the file (output).
!
! fin   = Default input file name (input)
! iin   = reading input unit (input).
! iwrit = if iwrit.eq.1, (x,y) pairs are written on screen (input).
!
	dimension x(*),y(*)
	character*40 fin
	character*40 comment
	LOGICAL EX
!
!  ********* read input file *********
!
! Check for default file "fin".  If file does not exist, then
! ask for a file name
!
!       write(*,*) fin
	go to 117
115     write(*,*) 'Input File Name ?? '
	READ(*,'(A)') fin
117	INQUIRE(FILE=fin,EXIST=EX)
	IF(.NOT.EX) THEN
	write(*,*) 'There is no trace defined'
	GO TO 115
	ENDIF
	OPEN(UNIT=iin,FILE=fin,STATUS='OLD')
!
	n = 1
	write(*,*)
120	continue
	READ(iin,'(a)',end=170,err = 150) comment
	read(comment,*,err = 150) xa,ya
	x(n) = xa
	y(n) = ya
	n = n + 1
	go to 120
150	continue
!       write(*,'(a)') comment
	go to 120
170	continue
	close(iin)
	n = n - 1
! ************************************************************
	if(n.ge.1) then
	   if(iwrit.eq.1) then
		write(*,*) '** Digitized traveltime data ** '
		write(*,*) ' '
		write(*,*) '            X(km)          T(sec)'
		write(*,*) ' '
		do i = 1,n
		  write(*,300) i,x(i),y(i)
		end do
		write(*,*) ' '
	   endif
	else
	write(*,*) '** There is no line containing data in this file **'
	endif
	
300	format(i5,2f15.6)

	return
	end
